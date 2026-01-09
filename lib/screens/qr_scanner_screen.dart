import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';
import 'streaming_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool isScanning = true;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionService.checkAndRequestPermissions(context);
    setState(() {
      hasPermission = granted;
    });

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.errorCameraPermission),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _handleQRCode(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      isScanning = false;
    });

    try {
      // Parse QR code data
      final data = jsonDecode(code);
      final sessionId = data['sessionId'] as String?;
      final serverUrl = data['serverUrl'] as String?;

      if (sessionId == null || serverUrl == null) {
        throw Exception('Invalid QR code data');
      }

      // Navigate to streaming screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              StreamingScreen(sessionId: sessionId, serverUrl: serverUrl),
        ),
      );
    } catch (e) {
      print('❌ Error parsing QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.errorInvalidQR),
          backgroundColor: AppConstants.errorColor,
        ),
      );

      // Resume scanning after error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isScanning = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !hasPermission
          ? _buildPermissionDenied()
          : Stack(
              children: [
                // QR Scanner View
                MobileScanner(controller: controller, onDetect: _handleQRCode),

                // Scan area overlay
                CustomPaint(
                  painter: ScannerOverlay(
                    borderColor: AppConstants.primaryColor,
                  ),
                  child: const SizedBox.expand(),
                ),

                // Top Bar
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            controller.toggleTorch();
                          },
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Instructions
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan QR Code',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Point your camera at the QR code\\ndisplayed on the receiver screen',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.errorCameraPermission,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _checkPermission();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  final Color borderColor;

  ScannerOverlay({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanArea = size.width * 0.7;
    final double left = (size.width - scanArea) / 2;
    final double top = (size.height - scanArea) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanArea, scanArea);

    // Draw semi-transparent overlay
    final Paint backgroundPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(20)),
        ),
      ),
      backgroundPaint,
    );

    // Draw corner borders
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 40;

    // Top-left corner
    canvas.drawLine(Offset(left, top + 20), Offset(left, top), borderPaint);
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanArea - cornerLength, top),
      Offset(left + scanArea, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanArea, top),
      Offset(left + scanArea, top + 20),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanArea - 20),
      Offset(left, top + scanArea),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanArea),
      Offset(left + cornerLength, top + scanArea),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanArea - cornerLength, top + scanArea),
      Offset(left + scanArea, top + scanArea),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanArea, top + scanArea),
      Offset(left + scanArea, top + scanArea - 20),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
