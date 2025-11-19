import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showScanQr(
  BuildContext context, {
  required void Function(BarcodeCapture barcodeCapture) onScanned,
  void Function(Object error)? onError,
  PreferredSizeWidget? appBar,
  Widget Function(BuildContext context, void Function() onPressed)? buttBuilder,
  bool scanFromGallery = true,
  BorderRadius? borderRadius,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadius ?? BorderRadius.zero,
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => TunaiScanQrScreen(
      onScanned: onScanned,
      onError: onError,
      appBar: appBar,
      buttBuilder: buttBuilder,
      scanFromGallery: scanFromGallery,
    ),
  );
}

class TunaiScanQrScreen extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final void Function(BarcodeCapture barcodeCapture) onScanned;
  final Widget Function(
    BuildContext context,
    void Function() onPressed,
  )? buttBuilder;
  final bool scanFromGallery;
  final void Function(Object error)? onError;
  const TunaiScanQrScreen({
    super.key,
    required this.onScanned,
    required this.buttBuilder,
    this.appBar,
    this.scanFromGallery = true,
    this.onError,
  });

  @override
  State<TunaiScanQrScreen> createState() => _TunaiScanQrScreenState();
}

class _TunaiScanQrScreenState extends State<TunaiScanQrScreen>
    with WidgetsBindingObserver {
  BarcodeCapture? _barcodeCaptures;

  final MobileScannerController _controller = MobileScannerController(
    detectionTimeoutMs: 1000,
    autoStart: false,
  );
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    startController();

    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      startController();
    }
  }

  void startController() async {
    try {
      await _controller.start();
    } catch (e) {
      widget.onError?.call(e);
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              startController();
            },
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
              onDetectError: (error, stackTrace) {
                widget.onError?.call(error);
              },
              overlayBuilder: (context, constraints) {
                return Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: constraints.maxWidth * 0.7,
                        height: constraints.maxHeight * 0.3,
                        child: Stack(
                          children: [
                            // Corner indicators
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.white, width: 3),
                                    left: BorderSide(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.white, width: 3),
                                    right: BorderSide(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.white, width: 3),
                                    left: BorderSide(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.white, width: 3),
                                    right: BorderSide(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              placeholderBuilder: (context) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              },
              errorBuilder: (context, e) {
                widget.onError?.call(e);
                final MobileScannerException exception = e;
                bool isPermissionDenied = exception.errorCode ==
                    MobileScannerErrorCode.permissionDenied;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPermissionDenied) ...[
                      Text(
                        'Please check your camera permission',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await openAppSettings();
                          } catch (e) {}
                        },
                        child: const Text(
                          'Request Permission',
                        ),
                      )
                    ],
                  ],
                );
              },
            ),
          ),
          if (widget.scanFromGallery)
            Positioned(
              left: 0,
              right: 0,
              bottom: max(MediaQuery.of(context).padding.bottom, 20),
              child: Center(
                child: widget.buttBuilder?.call(
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
