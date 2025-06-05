import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TunaiScanQrScreen extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final void Function(BarcodeCapture barcodeCapture) onScanned;
  final Widget Function(
    BuildContext context,
    void Function() onPressed,
  ) buttBuilder;
  final bool scanFromGallery;
  const TunaiScanQrScreen({
    super.key,
    required this.onScanned,
    required this.buttBuilder,
    this.appBar,
    this.scanFromGallery = true,
  });

  @override
  State<TunaiScanQrScreen> createState() => _TunaiScanQrScreenState();
}

class _TunaiScanQrScreenState extends State<TunaiScanQrScreen> {
  BarcodeCapture? _barcodeCaptures;

  final MobileScannerController _controller =
      MobileScannerController(detectionTimeoutMs: 1000, autoStart: false
          // cameraResolution: Size(1920, 1080),
          );
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller.start();

    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      if (barcodes != _barcodeCaptures) {
        widget.onScanned(barcodes);
      }
      setState(() {
        _barcodeCaptures = barcodes;
      });
    }
  }

  @override
  void dispose() async {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _controller.stop();
    super.dispose();
    await _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, e) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to open camera, please check your camera permission',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          SizedBox.expand(
            child: GestureDetector(
              onTap: () async {
                await _controller.stop();
                await _controller.start();
              },
              child: CustomPaint(
                painter: ScanWindowOverlayPainter(),
              ),
            ),
          ),
          if (widget.scanFromGallery)
            Positioned(
              left: 0,
              right: 0,
              bottom: max(MediaQuery.of(context).padding.bottom, 20),
              child: Center(
                child: widget.buttBuilder.call(
                  context,
                  () async {
                    ImagePicker picker = ImagePicker();

                    var img =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      String imagePath = img.path;

                      if (imagePath.isNotEmpty) {
                        final barcode =
                            await _controller.analyzeImage(imagePath);
                        if (barcode != null) {
                          _handleBarcode(barcode);
                        }
                      } else {
                        return null;
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScanWindowOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for dark edges
    final Paint paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    // Define the center rectangle for the scan window
    double scanWindowWidth = size.width * 0.6; // Customize width
    double scanWindowHeight = size.height * 0.25; // Customize height
    double scanWindowLeft = (size.width - scanWindowWidth) / 2;
    double scanWindowTop = (size.height - scanWindowHeight) / 2;

    // Draw the darkened edges around the transparent center
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Create transparent center area (scan window)
    paint.color = Colors.transparent; // Transparent center
    canvas.drawRect(
        Rect.fromLTWH(
            scanWindowLeft, scanWindowTop, scanWindowWidth, scanWindowHeight),
        paint);

    // Paint for the corner lines (white)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw the corner lines at the four corners
    double cornerSize = 20.0; // Size of the corner lines

    // Top-left corner
    canvas.drawLine(
      Offset(scanWindowLeft, scanWindowTop),
      Offset(scanWindowLeft + cornerSize, scanWindowTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindowLeft, scanWindowTop),
      Offset(scanWindowLeft, scanWindowTop + cornerSize),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanWindowLeft + scanWindowWidth, scanWindowTop),
      Offset(scanWindowLeft + scanWindowWidth - cornerSize, scanWindowTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindowLeft + scanWindowWidth, scanWindowTop),
      Offset(scanWindowLeft + scanWindowWidth, scanWindowTop + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanWindowLeft, scanWindowTop + scanWindowHeight),
      Offset(scanWindowLeft + cornerSize, scanWindowTop + scanWindowHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindowLeft, scanWindowTop + scanWindowHeight),
      Offset(scanWindowLeft, scanWindowTop + scanWindowHeight - cornerSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(
          scanWindowLeft + scanWindowWidth, scanWindowTop + scanWindowHeight),
      Offset(scanWindowLeft + scanWindowWidth - cornerSize,
          scanWindowTop + scanWindowHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(
          scanWindowLeft + scanWindowWidth, scanWindowTop + scanWindowHeight),
      Offset(scanWindowLeft + scanWindowWidth,
          scanWindowTop + scanWindowHeight - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
