import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen> {
  final VisitorService _visitorService = VisitorService();
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onQRDetected),
          // Overlay with scanning area
          CustomPaint(painter: ScannerOverlay(), child: Container()),
          // Instructions
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    // Verify the code
    final result = await _visitorService.verifyAccessCode(code);

    if (mounted) {
      if (result['success']) {
        final VisitorModel visitor = result['visitor'];
        // Show vehicle number popup first
        _showVehicleNumberDialog(visitor);
      } else {
        _showErrorDialog(result['message']);
      }
    }

    // Reset after showing dialog
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  void _showVisitorDetails(VisitorModel visitor) {
    cameraController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 10),
            const Text('Access Granted'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Visitor', visitor.visitorName),
              const Divider(height: 16),
              _buildInfoRow('Apartment', visitor.apartmentNumber),
              const Divider(height: 16),
              _buildInfoRow('Resident', visitor.residentName),
              const Divider(height: 16),
              _buildInfoRow('Phone', visitor.visitorPhone),
              const Divider(height: 16),
              _buildInfoRow('Type', _getVisitorTypeLabel(visitor.visitorType)),
              const Divider(height: 16),
              _buildInfoRow(
                'Valid Until',
                DateTimeFormatter.formatDateTime(visitor.validUntil),
              ),
              if (visitor.vehiclePlateNumber != null &&
                  visitor.vehiclePlateNumber!.isNotEmpty) ...[
                const Divider(height: 16),
                _buildInfoRow('Vehicle', visitor.vehiclePlateNumber!),
              ],
              if (visitor.visitorType == 'delivery') ...[
                const Divider(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'One-time use - will auto-deactivate',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              cameraController.start();
              setState(() {
                isProcessing = false;
              });
            },
            child: const Text('SCAN NEXT'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showVehicleNumberDialog(VisitorModel visitor) {
    final TextEditingController vehicleController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.blue[700], size: 32),
            const SizedBox(width: 10),
            const Text('Vehicle Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Does ${visitor.visitorName} have a vehicle?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: vehicleController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number Plate',
                hintText: 'e.g., MH12AB1234',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Skip - no vehicle
              Navigator.pop(context);
              _showVisitorDetails(visitor);
            },
            child: const Text('SKIP NO VEHICLE'),
          ),
          FilledButton(
            onPressed: () async {
              final vehicleNumber = vehicleController.text.trim();
              if (vehicleNumber.isNotEmpty) {
                // Update visitor with vehicle number
                await _visitorService.updateVehicleNumber(
                  visitor.id,
                  vehicleNumber,
                );
                // Update local visitor object
                visitor = visitor.copyWith(vehiclePlateNumber: vehicleNumber);
              }
              Navigator.pop(context);
              _showVisitorDetails(visitor);
            },
            child: const Text('ADD NUMBER'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    cameraController.stop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 32),
            const SizedBox(width: 10),
            const Text('Access Denied'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              cameraController.start();
              setState(() {
                isProcessing = false;
              });
            },
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _getVisitorTypeLabel(String type) {
    switch (type) {
      case 'guest':
        return 'Guest';
      case 'delivery':
        return 'Delivery';
      case 'frequent':
        return 'Frequent Visitor';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Scanner overlay painter
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    // Draw dark overlay around scan area
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
        ),
      ),
      paint,
    );

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const bracketLength = 30.0;

    // Top-left
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(0, bracketLength),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + const Offset(-bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + const Offset(0, bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(0, -bracketLength),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(-bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(0, -bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
