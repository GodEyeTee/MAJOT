import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';
import 'package:flutter/foundation.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRearCamera = true;
  bool _isFlashOn = false;
  bool _isProcessingImage = false;
  bool _isCameraInitializing = false;

  // Reset all flags
  void _resetFlags() {
    _isProcessingImage = false;
    _isCameraInitializing = false;
  }

  ScannerBloc() : super(ScannerInitial()) {
    on<InitializeCameraEvent>(_onInitializeCamera);
    on<TakePictureEvent>(_onTakePicture);
    on<PickImageFromGalleryEvent>(_onPickImageFromGallery);
    on<RetakePictureEvent>(_onRetakePicture);
    on<ConfirmScanEvent>(_onConfirmScan);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<SwitchCameraEvent>(_onSwitchCamera);
    on<PauseCameraEvent>(_onPauseCamera);
    on<ResumeCameraEvent>(_onResumeCamera);
    on<DisposeCameraEvent>(_onDisposeCamera);
  }

  Future<void> _onInitializeCamera(
    InitializeCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_isCameraInitializing) {
      debugPrint('⚠️ Camera already initializing, skipping...');
      return;
    }

    _resetFlags(); // Reset all flags
    _isCameraInitializing = true;
    emit(CameraLoading());
    debugPrint('🎥 Starting camera initialization...');

    try {
      // Clean dispose existing controller first
      await _cleanDispose();

      // Check camera permission
      debugPrint('🔐 Checking camera permission...');
      final cameraStatus = await Permission.camera.status;
      debugPrint('Initial permission status: $cameraStatus');

      if (!cameraStatus.isGranted) {
        debugPrint('📸 Requesting camera permission...');
        final result = await Permission.camera.request();
        debugPrint('Permission request result: $result');

        if (!result.isGranted) {
          debugPrint('❌ Camera permission denied');
          if (!emit.isDone) {
            emit(
              const ScannerError(
                'Camera permission denied. Please enable it in settings.',
              ),
            );
          }
          _isCameraInitializing = false;
          return;
        }
      }
      debugPrint('✅ Camera permission granted');

      // Get available cameras
      debugPrint('📷 Getting available cameras...');
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ No cameras found');
        if (!emit.isDone) {
          emit(const ScannerError('No cameras available on this device'));
        }
        _isCameraInitializing = false;
        return;
      }
      debugPrint('✅ Found ${_cameras!.length} cameras');

      // Find appropriate camera
      final camera = _cameras!.firstWhere(
        (cam) =>
            cam.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => _cameras!.first,
      );
      debugPrint('📸 Using ${camera.lensDirection} camera');

      // Initialize controller directly without Timer
      await _initializeController(camera);

      if (_controller != null && _controller!.value.isInitialized) {
        debugPrint('✅ Camera initialized successfully');
        if (!emit.isDone) {
          emit(
            CameraReady(
              controller: _controller!,
              isFlashOn: _isFlashOn,
              isRearCamera: _isRearCamera,
            ),
          );
        }
      } else {
        debugPrint('❌ Controller initialization failed');
        if (!emit.isDone) {
          emit(const ScannerError('Failed to initialize camera'));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Camera initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!emit.isDone) {
        emit(ScannerError('Camera initialization failed: ${e.toString()}'));
      }
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _onTakePicture(
    TakePictureEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_isProcessingImage ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      debugPrint(
        '⚠️ Cannot take picture - processing: $_isProcessingImage, controller null: ${_controller == null}',
      );
      return;
    }

    _isProcessingImage = true;
    debugPrint('📸 Taking picture...');

    try {
      // Set flash mode before taking picture
      if (_isRearCamera &&
          _controller!.value.flashMode !=
              (_isFlashOn ? FlashMode.torch : FlashMode.off)) {
        await _controller!.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }

      // Take picture
      final XFile picture = await _controller!.takePicture();
      debugPrint('✅ Picture taken: ${picture.path}');

      // Wait a bit before pausing to ensure image is saved
      await Future.delayed(const Duration(milliseconds: 200));

      // Pause preview to free resources
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !emit.isDone) {
        debugPrint('⏸️ Pausing preview after capture');
        try {
          await _controller!.pausePreview();
        } catch (e) {
          debugPrint('⚠️ Failed to pause preview: $e');
        }
      }

      if (!emit.isDone) {
        emit(PictureTaken(picture.path));
      }
    } catch (e) {
      debugPrint('❌ Take picture failed: $e');
      _isProcessingImage = false;

      // Try to resume preview on error
      try {
        if (_controller != null && _controller!.value.isInitialized) {
          await _controller!.resumePreview();
        }
      } catch (_) {}

      if (!emit.isDone) {
        emit(ScannerError('Failed to take picture: ${e.toString()}'));
      }
    }
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGalleryEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_isProcessingImage) return;

    _isProcessingImage = true;

    try {
      // Pause camera while picking from gallery
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.pausePreview();
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        if (!emit.isDone) {
          emit(PictureTaken(image.path));
        }
      } else {
        // Resume preview if no image selected
        _isProcessingImage = false; // Reset flag
        if (_controller != null && _controller!.value.isInitialized) {
          await _controller!.resumePreview();
        }
      }
    } catch (e) {
      _isProcessingImage = false; // Reset flag on error
      // Resume preview on error
      try {
        if (_controller != null && _controller!.value.isInitialized) {
          await _controller!.resumePreview();
        }
      } catch (_) {}

      if (!emit.isDone) {
        emit(ScannerError('Failed to pick image: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRetakePicture(
    RetakePictureEvent event,
    Emitter<ScannerState> emit,
  ) async {
    debugPrint(
      '🔄 Retake picture requested, current state: ${state.runtimeType}',
    );
    _isProcessingImage = false; // Always reset this flag

    // If already in CameraReady state, no need to do anything
    if (state is CameraReady) {
      debugPrint('✅ Already in CameraReady state');
      return;
    }

    // Small delay before resuming
    await Future.delayed(const Duration(milliseconds: 300));

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        debugPrint('📸 Controller available, checking preview state');
        // Make sure preview is resumed
        if (_controller!.value.isPreviewPaused) {
          debugPrint('▶️ Resuming preview for retake');
          await _controller!.resumePreview();
          // Additional delay after resume
          await Future.delayed(const Duration(milliseconds: 200));
        }

        if (!emit.isDone) {
          emit(
            CameraReady(
              controller: _controller!,
              isFlashOn: _isFlashOn,
              isRearCamera: _isRearCamera,
            ),
          );
          debugPrint('✅ Camera ready for retake');
        }
      } catch (e) {
        debugPrint('❌ Retake resume failed: $e');
        // If resume fails, reinitialize camera completely
        if (!emit.isDone) {
          emit(CameraLoading());
        }
        add(InitializeCameraEvent());
      }
    } else {
      debugPrint('⚠️ Controller not available for retake, reinitializing');
      // Controller not available, reinitialize
      if (!emit.isDone) {
        emit(CameraLoading());
      }
      add(InitializeCameraEvent());
    }
  }

  Future<void> _onConfirmScan(
    ConfirmScanEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (!emit.isDone) {
      emit(ScanProcessing());
    }

    // Keep camera paused during processing
    _isProcessingImage = true;

    // Simulate OCR processing
    await Future.delayed(const Duration(seconds: 2));

    // Reset flag after processing
    _isProcessingImage = false;

    if (!emit.isDone) {
      emit(const ScanCompleted('Scanned text will appear here'));
    }
  }

  Future<void> _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        state is! CameraReady ||
        !_isRearCamera) {
      return;
    }

    try {
      _isFlashOn = !_isFlashOn;

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      if (!emit.isDone) {
        emit(
          CameraReady(
            controller: _controller!,
            isFlashOn: _isFlashOn,
            isRearCamera: _isRearCamera,
          ),
        );
      }
    } catch (e) {
      _isFlashOn = !_isFlashOn;
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_cameras == null ||
        _cameras!.length < 2 ||
        _isProcessingImage ||
        _isCameraInitializing) {
      return;
    }

    _isCameraInitializing = true;
    _isRearCamera = !_isRearCamera;
    _isFlashOn = false; // Reset flash when switching

    if (!emit.isDone) {
      emit(CameraLoading());
    }

    try {
      final newCamera = _cameras!.firstWhere(
        (cam) =>
            cam.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );

      await _cleanDispose();
      await Future.delayed(const Duration(milliseconds: 300));

      await _initializeController(newCamera);

      if (_controller != null &&
          _controller!.value.isInitialized &&
          !emit.isDone) {
        emit(
          CameraReady(
            controller: _controller!,
            isFlashOn: _isFlashOn,
            isRearCamera: _isRearCamera,
          ),
        );
      }
    } catch (e) {
      _isRearCamera = !_isRearCamera; // Revert on error
      if (!emit.isDone) {
        emit(ScannerError('Failed to switch camera: ${e.toString()}'));
      }
      add(InitializeCameraEvent());
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _onPauseCamera(
    PauseCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        if (!_controller!.value.isPreviewPaused) {
          await _controller!.pausePreview();
        }
      } catch (e) {
        debugPrint('❌ Pause camera error: $e');
      }
    }
  }

  Future<void> _onResumeCamera(
    ResumeCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    debugPrint(
      '📸 Resume camera requested, current state: ${state.runtimeType}',
    );

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        // Check if preview is paused
        if (_controller!.value.isPreviewPaused) {
          debugPrint('▶️ Preview is paused, resuming...');
          await _controller!.resumePreview();
        }

        // Always emit CameraReady after successful resume
        if (!emit.isDone) {
          emit(
            CameraReady(
              controller: _controller!,
              isFlashOn: _isFlashOn,
              isRearCamera: _isRearCamera,
            ),
          );
          debugPrint('✅ Camera resumed successfully');
        }
      } catch (e) {
        debugPrint('❌ Resume camera error: $e');
        // If resume fails, reinitialize
        add(InitializeCameraEvent());
      }
    } else {
      // Controller not available or not initialized
      debugPrint('⚠️ Controller not available, reinitializing...');
      add(InitializeCameraEvent());
    }
  }

  Future<void> _onDisposeCamera(
    DisposeCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    debugPrint('🗑️ Dispose camera event received');
    _resetFlags(); // Reset all flags
    await _cleanDispose();
    if (!emit.isDone) {
      emit(ScannerInitial());
    }
  }

  Future<void> _initializeController(CameraDescription camera) async {
    try {
      debugPrint('🎥 Creating camera controller...');

      // Try different resolution presets if initialization fails
      final resolutionPresets = [
        ResolutionPreset.medium,
        ResolutionPreset.low,
        ResolutionPreset.low,
      ];

      for (final preset in resolutionPresets) {
        try {
          debugPrint('🎥 Trying resolution: $preset');

          // Ensure previous controller is disposed
          if (_controller != null) {
            try {
              await _controller!.dispose();
            } catch (_) {}
            _controller = null;
            await Future.delayed(const Duration(milliseconds: 200));
          }

          _controller = CameraController(
            camera,
            preset,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          debugPrint('🎥 Initializing controller with $preset...');
          // Add timeout to prevent hanging
          await _controller!.initialize().timeout(
            const Duration(seconds: 8), // Reduced from 10 to 8
            onTimeout: () {
              throw Exception('Camera initialization timeout');
            },
          );

          // Verify initialization
          if (!_controller!.value.isInitialized) {
            throw Exception(
              'Controller not initialized after initialize() call',
            );
          }

          debugPrint('✅ Controller initialized with $preset');

          // If successful, break the loop
          break;
        } catch (e) {
          debugPrint('❌ Failed with $preset: $e');
          if (_controller != null) {
            try {
              await _controller!.dispose();
            } catch (_) {}
            _controller = null;
          }

          // If this was the last preset, rethrow the error
          if (preset == resolutionPresets.last) {
            rethrow;
          }

          // Wait before trying next resolution
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Failed to initialize camera with any resolution');
      }

      // Wait to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Set flash mode if needed (only for rear camera)
      if (_isFlashOn && _isRearCamera) {
        try {
          await _controller!.setFlashMode(FlashMode.torch);
          debugPrint('🔦 Flash mode set to torch');
        } catch (e) {
          debugPrint('⚠️ Failed to set flash: $e');
          _isFlashOn = false;
        }
      }

      debugPrint('✅ Camera initialization complete');
    } catch (e) {
      debugPrint('❌ Camera initialization failed: $e');
      _controller = null;
      rethrow;
    }
  }

  Future<void> _cleanDispose() async {
    debugPrint('🧹 Starting clean dispose');

    if (_controller != null) {
      try {
        // Stop any ongoing operations
        if (_controller!.value.isInitialized) {
          // Stop image stream if active
          if (_controller!.value.isStreamingImages) {
            debugPrint('🛑 Stopping image stream before dispose');
            try {
              await _controller!.stopImageStream();
            } catch (e) {
              debugPrint('⚠️ Error stopping image stream: $e');
            }
          }

          // Pause preview if not already paused
          if (!_controller!.value.isPreviewPaused) {
            debugPrint('⏸️ Pausing preview before dispose');
            try {
              await _controller!.pausePreview();
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              debugPrint('⚠️ Error pausing preview: $e');
            }
          }
        }

        // Dispose controller
        debugPrint('🗑️ Disposing controller');
        await _controller!.dispose();
        _controller = null;

        // Give system more time to release resources
        debugPrint('⏳ Waiting for resources to release');
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('✅ Clean dispose complete');
      } catch (e) {
        debugPrint('❌ Dispose error: $e');
        // Force null even on error
        _controller = null;
        // Still wait even on error
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Future<void> close() async {
    debugPrint('🔒 Scanner BLoC closing');
    _resetFlags();
    await _cleanDispose();
    return super.close();
  }
}
