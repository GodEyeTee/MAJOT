import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRearCamera = true;
  bool _isFlashOn = false;

  ScannerBloc() : super(ScannerInitial()) {
    on<InitializeCameraEvent>(_onInitializeCamera);
    on<TakePictureEvent>(_onTakePicture);
    on<PickImageFromGalleryEvent>(_onPickImageFromGallery);
    on<RetakePictureEvent>(_onRetakePicture);
    on<ConfirmScanEvent>(_onConfirmScan);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<SwitchCameraEvent>(_onSwitchCamera);
  }

  Future<void> _onInitializeCamera(
    InitializeCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    emit(CameraLoading());

    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        emit(const ScannerError('Camera permission denied'));
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        emit(const ScannerError('No cameras available'));
        return;
      }

      // Initialize camera controller
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      emit(
        CameraReady(
          controller: _controller!,
          isFlashOn: _isFlashOn,
          isRearCamera: _isRearCamera,
        ),
      );
    } catch (e) {
      emit(ScannerError('Failed to initialize camera: ${e.toString()}'));
    }
  }

  Future<void> _onTakePicture(
    TakePictureEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      emit(const ScannerError('Camera not initialized'));
      return;
    }

    try {
      final XFile picture = await _controller!.takePicture();
      emit(PictureTaken(picture.path));
    } catch (e) {
      emit(ScannerError('Failed to take picture: ${e.toString()}'));
    }
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGalleryEvent event,
    Emitter<ScannerState> emit,
  ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        emit(PictureTaken(image.path));
      }
    } catch (e) {
      emit(ScannerError('Failed to pick image: ${e.toString()}'));
    }
  }

  Future<void> _onRetakePicture(
    RetakePictureEvent event,
    Emitter<ScannerState> emit,
  ) async {
    emit(
      CameraReady(
        controller: _controller!,
        isFlashOn: _isFlashOn,
        isRearCamera: _isRearCamera,
      ),
    );
  }

  Future<void> _onConfirmScan(
    ConfirmScanEvent event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScanProcessing());

    // Simulate OCR processing
    await Future.delayed(const Duration(seconds: 2));

    emit(const ScanCompleted('Scanned text will appear here'));
  }

  Future<void> _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_controller == null || state is! CameraReady) return;

    _isFlashOn = !_isFlashOn;

    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );

    emit(
      CameraReady(
        controller: _controller!,
        isFlashOn: _isFlashOn,
        isRearCamera: _isRearCamera,
      ),
    );
  }

  Future<void> _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<ScannerState> emit,
  ) async {
    if (_cameras == null || _cameras!.length < 2) return;

    emit(CameraLoading());

    _isRearCamera = !_isRearCamera;

    final newCamera = _cameras!.firstWhere(
      (cam) =>
          cam.lensDirection ==
          (_isRearCamera
              ? CameraLensDirection.back
              : CameraLensDirection.front),
    );

    await _controller?.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    emit(
      CameraReady(
        controller: _controller!,
        isFlashOn: false, // Reset flash when switching camera
        isRearCamera: _isRearCamera,
      ),
    );
  }

  @override
  Future<void> close() {
    _controller?.dispose();
    return super.close();
  }
}
