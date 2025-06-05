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
      create: (context) => ScannerBloc()..add(InitializeCameraEvent()),
      child: const ScannerView(),
    );
  }
}

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state is PictureTaken) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ScanPreviewPage(
                      imagePath: state.imagePath,
                      onConfirm: (croppedPath) {
                        context.read<ScannerBloc>().add(
                          ConfirmScanEvent(croppedPath),
                        );
                      },
                      onRetake: () {
                        context.read<ScannerBloc>().add(RetakePictureEvent());
                      },
                    ),
              ),
            );
          } else if (state is ScanCompleted) {
            // Navigate to result page or show result
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.result),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CameraLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (state is ScannerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ScannerBloc>().add(InitializeCameraEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CameraReady) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview with Overlay
                CameraPreviewWidget(
                  controller: state.controller,
                  onCapture: () {
                    context.read<ScannerBloc>().add(TakePictureEvent());
                  },
                ),

                // Top Controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 28,
                            ),

                            // Title
                            const Text(
                              'Scan Document',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Flash Toggle
                            IconButton(
                              onPressed: () {
                                context.read<ScannerBloc>().add(
                                  ToggleFlashEvent(),
                                );
                              },
                              icon: Icon(
                                state.isFlashOn
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                              ),
                              color:
                                  state.isFlashOn
                                      ? Colors.yellow
                                      : Colors.white,
                              iconSize: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            // Instruction Text
                            const Text(
                              'Position document within the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Gallery Button
                                _buildActionButton(
                                  icon: Icons.photo_library,
                                  label: 'Gallery',
                                  onPressed: () {
                                    context.read<ScannerBloc>().add(
                                      PickImageFromGalleryEvent(),
                                    );
                                  },
                                ),

                                // Capture Button
                                GestureDetector(
                                  onTap: () {
                                    context.read<ScannerBloc>().add(
                                      TakePictureEvent(),
                                    );
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // Switch Camera Button
                                _buildActionButton(
                                  icon: Icons.flip_camera_ios,
                                  label: 'Switch',
                                  onPressed: () {
                                    context.read<ScannerBloc>().add(
                                      SwitchCameraEvent(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is ScanProcessing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: Colors.white,
          iconSize: 32,
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
