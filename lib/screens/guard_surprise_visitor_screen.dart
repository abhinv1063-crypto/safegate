import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class GuardSurpriseVisitorScreen extends StatefulWidget {
  const GuardSurpriseVisitorScreen({super.key});

  @override
  State<GuardSurpriseVisitorScreen> createState() =>
      _GuardSurpriseVisitorScreenState();
}

class _GuardSurpriseVisitorScreenState
    extends State<GuardSurpriseVisitorScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController visitorNameController = TextEditingController();
  final TextEditingController visitorPhoneController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();

  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Surprise Visitor'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.purple[700],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send approval request to resident for unexpected visitor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Visitor Details',
              style: Theme.of(context).textTheme.displayMedium,
            ),

            const SizedBox(height: 20),

            // Visitor Name
            TextField(
              controller: visitorNameController,
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
              controller: visitorPhoneController,
              style: const TextStyle(fontSize: 18),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Visitor Phone *',
                labelStyle: const TextStyle(fontSize: 18),
                hintText: '10-digit number',
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

            const SizedBox(height: 20),

            // Apartment Number
            TextField(
              controller: apartmentController,
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Visiting Apartment *',
                labelStyle: const TextStyle(fontSize: 18),
                hintText: 'e.g., A-101',
                prefixIcon: const Icon(Icons.home, size: 28),
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

            // Remarks (Optional)
            TextField(
              controller: remarksController,
              style: const TextStyle(fontSize: 18),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks (Optional)',
                labelStyle: const TextStyle(fontSize: 18),
                hintText: 'Any additional information',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.note, size: 28),
                ),
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

            // Vehicle Number (Optional)
            TextField(
              controller: vehicleController,
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Vehicle Number (Optional)',
                labelStyle: const TextStyle(fontSize: 18),
                hintText: 'e.g., MH12AB1234',
                prefixIcon: const Icon(Icons.directions_car, size: 28),
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

            // Send Request Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: isSending ? null : _sendRequest,
                icon: isSending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 28),
                label: Text(
                  isSending ? 'SENDING REQUEST...' : 'SEND REQUEST',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 206, 19, 239),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    String visitorName = visitorNameController.text.trim();
    String visitorPhone = visitorPhoneController.text.trim();
    String apartment = apartmentController.text.trim();
    String remarks = remarksController.text.trim();
    String vehicleNumber = vehicleController.text.trim();

    // Validate
    if (visitorName.isEmpty) {
      _showError('Please enter visitor name');
      return;
    }

    if (visitorPhone.isEmpty || visitorPhone.length != 10) {
      _showError('Please enter valid 10-digit phone number');
      return;
    }

    if (apartment.isEmpty) {
      _showError('Please enter apartment number');
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      // Find the resident by searching across all apartment collections
      QuerySnapshot? residentsQuery;

      // List of apartment names (same as in login screen)
      final apartmentNames = [
        'Green Valley Apartments',
        'Sunrise Residency',
        'Royal Heights',
        'Palm Grove Apartments',
        'Lake View Residency',
        'Mountain View Apartments',
        'City Center Residency',
        'Garden View Apartments',
        'Elite Towers',
        'Harmony Apartments',
      ];

      // Search each apartment for the resident
      String? foundApartmentId;
      for (final apartmentName in apartmentNames) {
        final apartmentId = apartmentName.toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );

        final query = await _firestore
            .collection('apartments')
            .doc(apartmentId)
            .collection('users')
            .where('apartmentNumber', isEqualTo: apartment.toUpperCase())
            .get();

        if (query.docs.isNotEmpty) {
          residentsQuery = query;
          foundApartmentId = apartmentId;
          break;
        }
      }

      if (foundApartmentId == null ||
          residentsQuery == null ||
          residentsQuery.docs.isEmpty) {
        setState(() {
          isSending = false;
        });
        _showError(
          'Apartment $apartment not found. Please check the apartment number.',
        );
        return;
      }

      final residentData =
          residentsQuery.docs.first.data() as Map<String, dynamic>;
      final guardData = await _authService.getResidentData();

      if (guardData == null) {
        setState(() {
          isSending = false;
        });
        _showError('Unable to retrieve guard information.');
        return;
      }

      // Create visitor approval request
      final requestId = _firestore
          .collection('apartments')
          .doc(foundApartmentId)
          .collection('visitor_requests')
          .doc()
          .id;

      await _firestore
          .collection('apartments')
          .doc(foundApartmentId)
          .collection('visitor_requests')
          .doc(requestId)
          .set({
            'id': requestId,
            'visitorName': visitorName,
            'visitorPhone': visitorPhone,
            'apartmentNumber': apartment.toUpperCase(),
            'residentId': residentsQuery.docs.first.id,
            'residentName': residentData['residentName'] ?? 'Unknown Resident',
            'guardId': guardData['uid'],
            'guardName': guardData['residentName'] ?? 'Unknown Guard',
            'remarks': remarks,
            'vehiclePlateNumber': vehicleNumber.isNotEmpty
                ? vehicleNumber
                : null,
            'status': 'pending', // pending, approved, rejected
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        isSending = false;
      });

      if (mounted) {
        _showSuccess(
          'Request sent to ${residentData['residentName'] ?? 'Unknown Resident'} at apartment $apartment.\n\nWaiting for approval...',
        );
      }
    } catch (e) {
      setState(() {
        isSending = false;
      });
      _showError('Error sending request: ${e.toString()}');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 10),
            const Text('Error'),
          ],
        ),
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

  void _showSuccess(String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text('Request Sent'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Go back to guard home
            },
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    visitorNameController.dispose();
    visitorPhoneController.dispose();
    apartmentController.dispose();
    remarksController.dispose();
    vehicleController.dispose();
    super.dispose();
  }
}
