// camera_preview_widget.dart
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Scan Overlay
        CustomPaint(painter: ScanOverlayPainter(), child: Container()),
      ],
    );
  }
}

class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black54
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
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round;

    // Calculate frame dimensions
    final double frameWidth = size.width * 0.85;
    final double frameHeight = size.height * 0.5;
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;
    final double right = left + frameWidth;
    final double bottom = top + frameHeight;

    // Draw dark overlay with cutout
    final Path path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(left, top, right, bottom),
              const Radius.circular(12),
            ),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(12),
      ),
      framePaint,
    );

    // Draw corner accents
    const double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top + 12),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(left, top, 24, 24),
      3.14159, // π
      1.5708, // π/2
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 12, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(right - cornerLength, top),
      Offset(right - 12, top),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(right - 24, top, 24, 24),
      -1.5708, // -π/2
      1.5708, // π/2
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top + 12),
      Offset(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom - cornerLength),
      Offset(right, bottom - 12),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(right - 24, bottom - 24, 24, 24),
      0,
      1.5708, // π/2
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right - 12, bottom),
      Offset(right - cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left + cornerLength, bottom),
      Offset(left + 12, bottom),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(left, bottom - 24, 24, 24),
      1.5708, // π/2
      1.5708, // π/2
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom - 12),
      Offset(left, bottom - cornerLength),
      cornerPaint,
    );

    // Draw scanning animation lines
    final double scanLineY = top + (frameHeight * 0.5);
    final scanLinePaint =
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(left + 20, scanLineY),
      Offset(right - 20, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Utility class to get frame coordinates for cropping
class ScanFrameCalculator {
  static Rect getFrameRect(Size screenSize) {
    final double frameWidth = screenSize.width * 0.85;
    final double frameHeight = screenSize.height * 0.5;
    final double left = (screenSize.width - frameWidth) / 2;
    final double top = (screenSize.height - frameHeight) / 2;

    return Rect.fromLTWH(left, top, frameWidth, frameHeight);
  }

  static Map<String, double> getFrameCoordinates(
    Size screenSize,
    Size imageSize,
  ) {
    final frameRect = getFrameRect(screenSize);

    // Calculate scale factors
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
