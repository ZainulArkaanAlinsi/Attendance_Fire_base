import 'package:flutter/material.dart';

class FaceScannerOverlay extends StatefulWidget {
  final bool isScanning;
  final bool isSuccess;
  final bool isError;

  const FaceScannerOverlay({
    super.key,
    this.isScanning = false,
    this.isSuccess = false,
    this.isError = false,
  });

  @override
  State<FaceScannerOverlay> createState() => _FaceScannerOverlayState();
}

class _FaceScannerOverlayState extends State<FaceScannerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isScanning) {
      _scanController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FaceScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _scanController.repeat();
      _pulseController.repeat(reverse: true);
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _scanController.stop();
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ScannerPainter(
            scanProgress: _scanController.value,
            pulseProgress: _pulseController.value,
            color: widget.isError
                ? Colors.red
                : (widget.isSuccess ? Colors.green : Colors.blue.shade300),
            isScanning: widget.isScanning,
          ),
          child: const SizedBox(width: 280, height: 380),
        );
      },
    );
  }
}

class ScannerPainter extends CustomPainter {
  final double scanProgress;
  final double pulseProgress;
  final Color color;
  final bool isScanning;

  ScannerPainter({
    required this.scanProgress,
    required this.pulseProgress,
    required this.color,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5 + (0.5 * pulseProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    const radius = 40.0;

    // Draw corners
    const cornerLength = 40.0;

    // Top Left
    path.moveTo(0, cornerLength);
    path.lineTo(0, radius);
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
    );
    path.lineTo(cornerLength, 0);

    // Top Right
    path.moveTo(width - cornerLength, 0);
    path.lineTo(width - radius, 0);
    path.arcToPoint(
      Offset(width, radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(width, cornerLength);

    // Bottom Right
    path.moveTo(width, height - cornerLength);
    path.lineTo(width, height - radius);
    path.arcToPoint(
      Offset(width - radius, height),
      radius: const Radius.circular(radius),
    );
    path.lineTo(width - cornerLength, height);

    // Bottom Left
    path.moveTo(cornerLength, height);
    path.lineTo(radius, height);
    path.arcToPoint(
      Offset(0, height - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(0, height - cornerLength);

    canvas.drawPath(path, paint);

    if (isScanning) {
      // Draw scan line
      final scanPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, scanProgress * height - 20, width, 40));

      canvas.drawRect(
        Rect.fromLTWH(5, scanProgress * height, width - 10, 2),
        Paint()..color = color,
      );

      canvas.drawRect(
        Rect.fromLTWH(5, scanProgress * height - 20, width - 10, 40),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerPainter oldDelegate) => true;
}
