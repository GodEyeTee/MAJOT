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

  @override
  void initState() {
    super.initState();
    _autoCropImage();
  }

  Future<void> _autoCropImage() async {
    setState(() => _isProcessing = true);

    try {
      // Read the original image
      final originalFile = File(widget.imagePath);
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Get screen size for frame calculation
        final screenSize = MediaQuery.of(context).size;
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());

        // Calculate crop coordinates based on frame
        final coords = ScanFrameCalculator.getFrameCoordinates(
          screenSize,
          imageSize,
        );

        // Crop the image
        final cropped = img.copyCrop(
          image,
          x: coords['left']!.round(),
          y: coords['top']!.round(),
          width: coords['width']!.round(),
          height: coords['height']!.round(),
        );

        // Save cropped image
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(img.encodeJpg(cropped));

        setState(() {
          _croppedImagePath = tempFile.path;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _croppedImagePath = widget.imagePath;
        _isProcessing = false;
      });
    }
  }

  Future<void> _manualCrop() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _croppedImagePath ?? widget.imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Scan',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: Colors.yellow,
        ),
        IOSUiSettings(
          title: 'Adjust Scan',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _croppedImagePath = croppedFile.path;
      });
    }
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
                    onPressed: _manualCrop,
                    icon: const Icon(Icons.crop),
                    color: Colors.white,
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
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
                  child:
                      _isProcessing
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : Image.file(
                            File(_croppedImagePath ?? widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Retake Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.onRetake();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
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
                      onPressed:
                          _isProcessing
                              ? null
                              : () {
                                widget.onConfirm(
                                  _croppedImagePath ?? widget.imagePath,
                                );
                                Navigator.of(context).pop();
                              },
                      icon: const Icon(Icons.check),
                      label: const Text('Use Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
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
