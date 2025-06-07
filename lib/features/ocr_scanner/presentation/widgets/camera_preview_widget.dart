import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onCapture;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview - Simple implementation to reduce buffer usage
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Scan Overlay
        IgnorePointer(
          child: CustomPaint(size: size, painter: ScanOverlayPainter()),
        ),
      ],
    );
  }
}

class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final framePaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    final cornerPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;

    // Calculate frame dimensions
    final frameRect = ScanFrameCalculator.getFrameRect(size);

    // Draw dark overlay with cutout
    final Path path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame border
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      framePaint,
    );

    // Draw corner accents
    const double cornerLength = 25;
    final left = frameRect.left;
    final top = frameRect.top;
    final right = frameRect.right;
    final bottom = frameRect.bottom;

    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top + 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 12, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(right - cornerLength, top),
      Offset(right - 12, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top + 12),
      Offset(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(right, bottom - cornerLength),
      Offset(right, bottom - 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right - 12, bottom),
      Offset(right - cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left + cornerLength, bottom),
      Offset(left + 12, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom - 12),
      Offset(left, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Utility class for frame calculations
class ScanFrameCalculator {
  static const double _frameWidthRatio = 0.85;
  static const double _frameHeightRatio = 0.5;

  static Rect getFrameRect(Size screenSize) {
    final double frameWidth = screenSize.width * _frameWidthRatio;
    final double frameHeight = screenSize.height * _frameHeightRatio;
    final double left = (screenSize.width - frameWidth) / 2;
    final double top = (screenSize.height - frameHeight) / 2;

    return Rect.fromLTWH(left, top, frameWidth, frameHeight);
  }

  static Map<String, double> getFrameCoordinates(
    Size screenSize,
    Size imageSize,
  ) {
    final frameRect = getFrameRect(screenSize);

    // Simple scaling calculation
    final double scaleX = imageSize.width / screenSize.width;
    final double scaleY = imageSize.height / screenSize.height;

    return {
      'left': frameRect.left * scaleX,
      'top': frameRect.top * scaleY,
      'width': frameRect.width * scaleX,
      'height': frameRect.height * scaleY,
    };
  }
}
