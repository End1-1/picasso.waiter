import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';

class BarcodeScannerWithOverlay extends StatefulWidget {
  const BarcodeScannerWithOverlay({super.key});

  @override
  State<BarcodeScannerWithOverlay> createState() =>
      _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isDetecting = false;
  bool _isClosed = false;
  List<ResultPoint>? _lastPoints;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;

    _controller.startImageStream((image) {
      if (_isDetecting || _isClosed) return;
      _isDetecting = true;
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) async {
    try {
      final width = image.width;
      final height = image.height;

      // Берём Y-плоскость (grayscale)
      final yBuffer = image.planes[0].bytes;

      // Конвертируем в int массив под RGBLuminanceSource
      final pixels = Int32List(width * height);
      for (int i = 0; i < yBuffer.length; i++) {
        final luma = yBuffer[i] & 0xFF;
        pixels[i] = (0xFF << 24) | (luma << 16) | (luma << 8) | luma;
      }

      final source = RGBLuminanceSource(width, height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));

      final reader = QRCodeReader();

      final result = reader.decode(bitmap);

      if (!_isClosed && mounted) {
        setState(() {
          _lastPoints = result.resultPoints;
        });

        _isClosed = true;
        Navigator.of(context).pop(result.text);
      }
    } catch (_) {
      setState(() => _lastPoints = null);
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _isClosed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),
                if (_lastPoints != null)
                  CustomPaint(
                    painter: _BarcodeOverlayPainter(
                      points: _lastPoints!,
                      previewSize: _controller.value.previewSize!,
                    ),
                  ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class _BarcodeOverlayPainter extends CustomPainter {
  final List<ResultPoint> points;
  final Size previewSize;

  _BarcodeOverlayPainter({required this.points, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / previewSize.height; // камера повернута
    final scaleY = size.height / previewSize.width;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final offset = Offset(p.x * scaleX, p.y * scaleY);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    if (points.length > 2) path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BarcodeOverlayPainter oldDelegate) =>
      oldDelegate.points != points;
}
