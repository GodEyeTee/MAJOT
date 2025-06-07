import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_spacing.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';
import '../widgets/camera_preview_widget.dart';
import 'scan_preview_page.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ScannerBloc()..add(InitializeCameraEvent());
        // Add listener to auto-initialize if needed
        bloc.stream.listen((state) {
          if (state is ScannerInitial) {
            debugPrint('🎬 Scanner in initial state, initializing camera...');
            bloc.add(InitializeCameraEvent());
          }
        });
        return bloc;
      },
      child: const ScannerView(),
    );
  }
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  bool _isNavigating = false;
  bool _isPaused = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🎬 Scanner View initState');
  }

  @override
  void dispose() {
    debugPrint('🎬 Scanner View dispose');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    // Dispose camera when leaving page
    final bloc = context.read<ScannerBloc>();
    bloc.add(DisposeCameraEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    final bloc = context.read<ScannerBloc>();
    debugPrint('🎬 App lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (!_isPaused && !_isNavigating) {
          _isPaused = true;
          bloc.add(PauseCameraEvent());
        }
        break;
      case AppLifecycleState.resumed:
        if (_isPaused && !_isNavigating && mounted) {
          _isPaused = false;
          // Delay resume to ensure proper initialization
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isDisposed) {
              bloc.add(ResumeCameraEvent());
            }
          });
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handlePictureTaken(String imagePath) {
    if (_isNavigating || _isDisposed) return;

    _isNavigating = true;
    debugPrint('🎬 Navigating to preview');

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => ScanPreviewPage(
                  imagePath: imagePath,
                  onConfirm: (croppedPath) {
                    if (!_isDisposed) {
                      context.read<ScannerBloc>().add(
                        ConfirmScanEvent(croppedPath),
                      );
                    }
                  },
                  onRetake: () {
                    debugPrint('🎬 Retake requested');
                    if (!_isDisposed) {
                      context.read<ScannerBloc>().add(RetakePictureEvent());
                    }
                  },
                ),
          ),
        )
        .then((_) {
          debugPrint('🎬 Back from preview');
          _isNavigating = false;

          // Ensure camera is resumed when coming back
          if (mounted && !_isDisposed) {
            final currentState = context.read<ScannerBloc>().state;
            debugPrint(
              '🎬 Current state after back: ${currentState.runtimeType}',
            );

            // Force resume if not in camera ready state
            if (currentState is! CameraReady) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && !_isDisposed) {
                  context.read<ScannerBloc>().add(ResumeCameraEvent());
                }
              });
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          debugPrint('🎬 Scanner state: ${state.runtimeType}');

          if (state is PictureTaken && !_isNavigating && !_isDisposed) {
            _handlePictureTaken(state.imagePath);
          } else if (state is ScanCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.result),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Return to camera after showing result
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isDisposed) {
                context.read<ScannerBloc>().add(RetakePictureEvent());
              }
            });
          }
        },
        builder: (context, state) {
          if (state is CameraLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (state is ScannerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<ScannerBloc>().add(
                              InitializeCameraEvent(),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push('/camera-test');
                          },
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Debug'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CameraReady) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreviewWidget(
                  controller: state.controller,
                  onCapture: () {
                    if (!_isNavigating && !_isDisposed) {
                      context.read<ScannerBloc>().add(TakePictureEvent());
                    }
                  },
                ),

                // Top Controls
                _buildTopControls(context, state),

                // Bottom Controls
                _buildBottomControls(context, state),
              ],
            );
          }

          if (state is ScanProcessing) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.yellow,
                      strokeWidth: 4,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initial state or unknown state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'State: ${state.runtimeType}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ScannerBloc>().add(InitializeCameraEvent());
                  },
                  child: const Text('Initialize Camera'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopControls(BuildContext context, CameraReady state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Ensure camera is disposed when leaving
                      context.read<ScannerBloc>().add(DisposeCameraEvent());
                      context.pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Title
                const Text(
                  'Scan Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                // Flash Toggle (only for rear camera)
                if (state.isRearCamera)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<ScannerBloc>().add(ToggleFlashEvent());
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          state.isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: state.isFlashOn ? Colors.yellow : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, CameraReady state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.9),
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Debug Info (temporary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Camera: ${state.isRearCamera ? "Rear" : "Front"} | Flash: ${state.isFlashOn ? "On" : "Off"}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instruction Text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Position document within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    _ActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onPressed: () {
                        if (!_isNavigating && !_isDisposed) {
                          context.read<ScannerBloc>().add(
                            PickImageFromGalleryEvent(),
                          );
                        }
                      },
                    ),

                    // Capture Button
                    _CaptureButton(
                      onPressed: () {
                        if (!_isNavigating && !_isDisposed) {
                          context.read<ScannerBloc>().add(TakePictureEvent());
                        }
                      },
                    ),

                    // Switch Camera Button
                    _ActionButton(
                      icon: Icons.flip_camera_android_outlined,
                      label: 'Switch',
                      onPressed: () {
                        if (!_isNavigating && !_isDisposed) {
                          context.read<ScannerBloc>().add(SwitchCameraEvent());
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Capture button with debouncing
class _CaptureButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CaptureButton({required this.onPressed});

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isPressed) return;

    setState(() => _isPressed = true);
    _animationController.forward();

    widget.onPressed();

    // Reset after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _animationController.reverse();
        setState(() => _isPressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _handleTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressed ? Colors.grey[300] : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
