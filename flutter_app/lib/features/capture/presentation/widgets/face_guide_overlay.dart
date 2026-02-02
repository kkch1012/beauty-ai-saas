import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/constants/app_theme.dart';

class FaceGuideOverlay extends StatelessWidget {
  final List<Face> faces;
  final Size previewSize;

  const FaceGuideOverlay({
    super.key,
    required this.faces,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FaceGuidePainter(
        faces: faces,
        previewSize: previewSize,
        screenSize: MediaQuery.of(context).size,
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final Size screenSize;

  _FaceGuidePainter({
    required this.faces,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw face oval guide
    _drawFaceOvalGuide(canvas, size);

    // Draw detected face landmarks
    if (faces.isNotEmpty) {
      _drawFaceLandmarks(canvas, size, faces.first);
      _drawGoldenRatioGuide(canvas, size, faces.first);
    }
  }

  void _drawFaceOvalGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Face oval in center
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 50;
    final ovalWidth = size.width * 0.55;
    final ovalHeight = ovalWidth * 1.4;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    canvas.drawOval(rect, paint);

    // Draw corner guides
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top left
    canvas.drawLine(
      Offset(rect.left, rect.top + ovalHeight * 0.1),
      Offset(rect.left, rect.top + ovalHeight * 0.1 + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + ovalHeight * 0.1),
      Offset(rect.left + cornerLength, rect.top + ovalHeight * 0.1),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(rect.right, rect.top + ovalHeight * 0.1),
      Offset(rect.right, rect.top + ovalHeight * 0.1 + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + ovalHeight * 0.1),
      Offset(rect.right - cornerLength, rect.top + ovalHeight * 0.1),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(rect.left, rect.bottom - ovalHeight * 0.1),
      Offset(rect.left, rect.bottom - ovalHeight * 0.1 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - ovalHeight * 0.1),
      Offset(rect.left + cornerLength, rect.bottom - ovalHeight * 0.1),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(rect.right, rect.bottom - ovalHeight * 0.1),
      Offset(rect.right, rect.bottom - ovalHeight * 0.1 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - ovalHeight * 0.1),
      Offset(rect.right - cornerLength, rect.bottom - ovalHeight * 0.1),
      cornerPaint,
    );
  }

  void _drawFaceLandmarks(Canvas canvas, Size size, Face face) {
    final paint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;

    final scaleX = size.width / previewSize.height; // Camera is rotated
    final scaleY = size.height / previewSize.width;

    // Draw eyebrow landmarks
    _drawContour(
      canvas,
      face.contours[FaceContourType.leftEyebrowTop],
      paint,
      scaleX,
      scaleY,
      size,
    );
    _drawContour(
      canvas,
      face.contours[FaceContourType.rightEyebrowTop],
      paint,
      scaleX,
      scaleY,
      size,
    );
  }

  void _drawContour(
    Canvas canvas,
    FaceContour? contour,
    Paint paint,
    double scaleX,
    double scaleY,
    Size size,
  ) {
    if (contour == null) return;

    for (final point in contour.points) {
      // Mirror for front camera
      final x = size.width - (point.x * scaleX);
      final y = point.y * scaleY;

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  void _drawGoldenRatioGuide(Canvas canvas, Size size, Face face) {
    final paint = Paint()
      ..color = AppColors.warning.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Get face bounding box
    final bbox = face.boundingBox;
    final scaleX = size.width / previewSize.height;
    final scaleY = size.height / previewSize.width;

    // Calculate ideal eyebrow position based on golden ratio
    final faceWidth = bbox.width * scaleX;
    final faceTop = bbox.top * scaleY;

    // Golden ratio: eyebrow should be at ~1/3 from top of face
    final idealEyebrowY = faceTop + (bbox.height * scaleY * 0.25);

    // Draw horizontal guide line at ideal eyebrow height
    final dashPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dashed line
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double startX = size.width * 0.2;
    final endX = size.width * 0.8;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, idealEyebrowY),
        Offset(startX + dashWidth, idealEyebrowY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
