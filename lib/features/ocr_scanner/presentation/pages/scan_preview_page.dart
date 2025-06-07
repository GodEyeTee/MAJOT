import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../../../../core/themes/app_spacing.dart';
import '../widgets/camera_preview_widget.dart';

class ScanPreviewPage extends StatefulWidget {
  final String imagePath;
  final Function(String) onConfirm;
  final VoidCallback onRetake;

  const ScanPreviewPage({
    super.key,
    required this.imagePath,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  State<ScanPreviewPage> createState() => _ScanPreviewPageState();
}

class _ScanPreviewPageState extends State<ScanPreviewPage> {
  String? _croppedImagePath;
  bool _isProcessing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _autoCropImage();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    // Clean up temporary cropped files
    if (_croppedImagePath != null && _croppedImagePath != widget.imagePath) {
      try {
        final file = File(_croppedImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  Future<void> _autoCropImage() async {
    if (_isDisposed) return;

    setState(() => _isProcessing = true);

    try {
      // Read the original image
      final originalFile = File(widget.imagePath);
      if (!await originalFile.exists()) {
        throw Exception('Image file not found');
      }

      final bytes = await originalFile.readAsBytes();

      // Decode image in isolate to prevent UI blocking
      final image = img.decodeImage(bytes);

      if (image != null && mounted) {
        // Get screen size for frame calculation
        final screenSize = MediaQuery.of(context).size;
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());

        // Calculate crop coordinates based on frame
        final coords = ScanFrameCalculator.getFrameCoordinates(
          screenSize,
          imageSize,
        );

        // Validate coordinates
        final cropX = coords['left']!.round().clamp(0, image.width - 1);
        final cropY = coords['top']!.round().clamp(0, image.height - 1);
        final cropWidth = coords['width']!.round().clamp(
          1,
          image.width - cropX,
        );
        final cropHeight = coords['height']!.round().clamp(
          1,
          image.height - cropY,
        );

        // Crop the image
        final cropped = img.copyCrop(
          image,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        // Save cropped image
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/scan_cropped_$timestamp.jpg');

        // Encode with reasonable quality to save memory
        await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 85));

        if (mounted && !_isDisposed) {
          setState(() {
            _croppedImagePath = tempFile.path;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Auto crop error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _croppedImagePath = widget.imagePath;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _manualCrop() async {
    if (_isProcessing || _isDisposed) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _croppedImagePath ?? widget.imagePath,
        maxWidth: 2000, // Limit max size to prevent memory issues
        maxHeight: 2000,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Scan',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor: Colors.yellow,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Adjust Scan',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
            aspectRatioLockEnabled: false,
            resetButtonHidden: false,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null && mounted && !_isDisposed) {
        // Clean up old cropped file
        if (_croppedImagePath != null &&
            _croppedImagePath != widget.imagePath) {
          try {
            await File(_croppedImagePath!).delete();
          } catch (e) {
            // Ignore cleanup errors
          }
        }

        setState(() {
          _croppedImagePath = croppedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Manual crop error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to crop image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmImage() {
    if (_isProcessing || _isDisposed) return;

    final imagePath = _croppedImagePath ?? widget.imagePath;
    widget.onConfirm(imagePath);
    Navigator.of(context).pop();
  }

  void _retakeImage() {
    if (_isDisposed) return;

    widget.onRetake();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 28,
                  ),
                  const Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing ? null : _manualCrop,
                    icon: const Icon(Icons.crop),
                    color: _isProcessing ? Colors.grey : Colors.white,
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                child:
                    _isProcessing
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Processing image...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_croppedImagePath ?? widget.imagePath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Retake Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _retakeImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _isProcessing ? Colors.grey : Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Use Photo Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _confirmImage,
                      icon: const Icon(Icons.check),
                      label: const Text('Use Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isProcessing ? Colors.grey : Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
