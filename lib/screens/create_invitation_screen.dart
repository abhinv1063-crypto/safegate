import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';

class CreateInvitationScreen extends StatefulWidget {
  const CreateInvitationScreen({super.key});

  @override
  State<CreateInvitationScreen> createState() => _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends State<CreateInvitationScreen> {
  final AuthService _authService = AuthService();
  final VisitorService _visitorService = VisitorService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Global key to capture QR code as image
  final GlobalKey _qrKey = GlobalKey();

  DateTime selectedValidFrom = DateTime.now();
  DateTime selectedValidUntil = DateTime.now().add(const Duration(hours: 6));

  bool isLoading = false;
  bool isSharingQR = false;
  VisitorModel? generatedInvitation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Invite Visitor'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: generatedInvitation == null
          ? _buildInvitationForm()
          : _buildQRCodeDisplay(),
    );
  }

  // Form to enter visitor details
  Widget _buildInvitationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info text
          Text(
            'Enter Visitor Details',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Generate a QR code for your visitor to show at the gate',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),

          // Visitor Name
          TextField(
            controller: nameController,
            style: const TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Visitor Name *',
              labelStyle: const TextStyle(fontSize: 18),
              hintText: 'e.g., John Doe',
              prefixIcon: const Icon(Icons.person, size: 28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Visitor Phone
          TextField(
            controller: phoneController,
            style: const TextStyle(fontSize: 18),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Visitor Phone *',
              labelStyle: const TextStyle(fontSize: 18),
              hintText: '10-digit mobile number',
              prefixIcon: const Icon(Icons.phone, size: 28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Valid From
          Text(
            'Valid From',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, size: 28),
              title: Text(
                DateTimeFormatter.formatDateTime(selectedValidFrom),
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectValidFrom(),
            ),
          ),

          const SizedBox(height: 20),

          // Valid Until
          Text(
            'Valid Until',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event, size: 28),
              title: Text(
                DateTimeFormatter.formatDateTime(selectedValidUntil),
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectValidUntil(),
            ),
          ),

          const SizedBox(height: 30),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _generateInvitation,
              icon: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code, size: 28),
              label: Text(
                isLoading ? 'GENERATING...' : 'GENERATE QR CODE',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Display the generated QR code
  Widget _buildQRCodeDisplay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Success icon
          Icon(Icons.check_circle, size: 80, color: Colors.green[700]),
          const SizedBox(height: 20),

          Text(
            'Invitation Created!',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: Colors.green[700]),
          ),

          const SizedBox(height: 30),

          // QR Code with RepaintBoundary to capture as image
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SafeGate',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  QrImageView(
                    data: generatedInvitation!.accessCode,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  // Visitor details on QR
                  Text(
                    generatedInvitation!.visitorName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apartment ${generatedInvitation!.apartmentNumber}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valid: ${DateTimeFormatter.formatDateTime(generatedInvitation!.validFrom, showTime: false)} to ${DateTimeFormatter.formatDateTime(generatedInvitation!.validUntil, showTime: false)}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Visitor Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Visitor', generatedInvitation!.visitorName),
                  const Divider(height: 20),
                  _buildDetailRow('Phone', generatedInvitation!.visitorPhone),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Valid From',
                    DateTimeFormatter.formatDateTime(
                      generatedInvitation!.validFrom,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Valid Until',
                    DateTimeFormatter.formatDateTime(
                      generatedInvitation!.validUntil,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Access Code',
                    generatedInvitation!.accessCode,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Share QR Code Button (with image)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: isSharingQR ? null : _shareQRCodeImage,
              icon: isSharingQR
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share, size: 28),
              label: Text(
                isSharingQR ? 'PREPARING...' : 'SHARE QR CODE',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Create Another Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  generatedInvitation = null;
                  nameController.clear();
                  phoneController.clear();
                });
              },
              icon: const Icon(Icons.add, size: 28),
              label: const Text(
                'CREATE ANOTHER',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Done Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DONE', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

  // Select Valid From date and time
  Future<void> _selectValidFrom() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedValidFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedValidFrom),
      );

      if (pickedTime != null) {
        setState(() {
          selectedValidFrom = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Select Valid Until date and time
  Future<void> _selectValidUntil() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedValidUntil,
      firstDate: selectedValidFrom,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedValidUntil),
      );

      if (pickedTime != null) {
        setState(() {
          selectedValidUntil = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Generate invitation
  Future<void> _generateInvitation() async {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();

    // Validate
    if (name.isEmpty) {
      _showError('Please enter visitor name');
      return;
    }

    if (phone.isEmpty || phone.length != 10) {
      _showError('Please enter valid 10-digit phone number');
      return;
    }

    if (selectedValidFrom.isAfter(selectedValidUntil)) {
      _showError('Valid from time must be before valid until time');
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Get resident data
    final residentData = await _authService.getResidentData();

    if (residentData == null) {
      setState(() {
        isLoading = false;
      });
      _showError('Could not load your profile');
      return;
    }

    // Create invitation
    String apartmentId = residentData['apartmentName']
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    final result = await _visitorService.createGuestInvitation(
      apartmentId: apartmentId,
      residentId: residentData['uid'],
      residentName: residentData['residentName'],
      apartmentNumber: residentData['apartmentNumber'],
      visitorName: name,
      visitorPhone: phone,
      validFrom: selectedValidFrom,
      validUntil: selectedValidUntil,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      setState(() {
        generatedInvitation = result['visitor'];
      });
    } else {
      _showError(result['message']);
    }
  }

  // Capture QR code as image and share
  Future<void> _shareQRCodeImage() async {
    if (generatedInvitation == null) return;

    setState(() {
      isSharingQR = true;
    });

    try {
      // Find the render object
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture as image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/safegate_qr_${generatedInvitation!.visitorName}.png',
      );
      await file.writeAsBytes(pngBytes);

      // Create message
      String message =
          '''
🏠 SafeGate Visitor Pass

Hello ${generatedInvitation!.visitorName}!

You're invited to Apartment ${generatedInvitation!.apartmentNumber}.

Please show this QR code at the security gate.

⏰ Valid From: ${DateTimeFormatter.formatDateTime(generatedInvitation!.validFrom)}
⏰ Valid Until: ${DateTimeFormatter.formatDateTime(generatedInvitation!.validUntil)}

Safe travels!
''';

      // Share using share_plus
      await Share.shareXFiles([XFile(file.path)], text: message);
    } catch (e) {
      _showError('Error sharing QR code: $e');
    } finally {
      setState(() {
        isSharingQR = false;
      });
    }
  }

  // Show error
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
