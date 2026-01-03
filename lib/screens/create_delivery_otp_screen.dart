import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';

class CreateDeliveryOTPScreen extends StatefulWidget {
  const CreateDeliveryOTPScreen({super.key});

  @override
  State<CreateDeliveryOTPScreen> createState() =>
      _CreateDeliveryOTPScreenState();
}

class _CreateDeliveryOTPScreenState extends State<CreateDeliveryOTPScreen> {
  final AuthService _authService = AuthService();
  final VisitorService _visitorService = VisitorService();

  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  VisitorModel? generatedOTP;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Delivery OTP'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: generatedOTP == null ? _buildOTPForm() : _buildOTPDisplay(),
    );
  }

  // Form to enter delivery partner details
  Widget _buildOTPForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OTP expires after ONE use or when validity period ends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Info text
          Text(
            'Generate Delivery Code',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Create a one-time passcode for your delivery',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),

          // Delivery Partner Name
          TextField(
            controller: nameController,
            style: const TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Delivery Partner *',
              labelStyle: const TextStyle(fontSize: 18),
              hintText: 'e.g., Amazon, Zomato',
              prefixIcon: const Icon(Icons.local_shipping, size: 28),
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

          // Quick suggestions
          Text(
            'Quick Select',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickChip('Amazon'),
              _buildQuickChip('Flipkart'),
              _buildQuickChip('Zomato'),
              _buildQuickChip('Swiggy'),
              _buildQuickChip('Blinkit'),
              _buildQuickChip('Zepto'),
              _buildQuickChip('Instamart'),
              _buildQuickChip('Dunzo'),
              _buildQuickChip('BigBasket'),
              _buildQuickChip('Myntra'),
              _buildQuickChip('Meesho'),
              _buildQuickChip('Other'),
            ],
          ),
          const SizedBox(height: 30),

          // Generate OTP Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _generateOTP,
              icon: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.pin, size: 28),
              label: Text(
                isLoading ? 'GENERATING...' : 'GENERATE OTP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
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

  // Display the generated OTP
  Widget _buildOTPDisplay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Success icon
          Icon(Icons.check_circle, size: 80, color: Colors.orange[700]),
          const SizedBox(height: 20),

          Text(
            'OTP Generated!',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: Colors.orange[700]),
          ),

          const SizedBox(height: 30),

          // OTP Display Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'ONE-TIME PASSCODE',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // OTP in large font
                Text(
                  generatedOTP!.accessCode,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),

                const SizedBox(height: 20),

                // Copy button
                TextButton.icon(
                  onPressed: _copyOTP,
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text(
                    'TAP TO COPY',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Delivery Partner',
                    generatedOTP!.visitorName,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Apartment', generatedOTP!.apartmentNumber),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Valid Until',
                    DateTimeFormatter.formatDateTime(generatedOTP!.validUntil),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expires after single use',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _shareOTP,
              icon: const Icon(Icons.share, size: 28),
              label: const Text(
                'SHARE OTP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
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
                  generatedOTP = null;
                  nameController.clear();
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

  // Quick chip for common services
  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        nameController.text = label;
      },
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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

  // Generate OTP
  Future<void> _generateOTP() async {
    String name = nameController.text.trim();

    // Validate
    if (name.isEmpty) {
      _showError('Please enter delivery partner name');
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

    // Create OTP with dummy phone number
    String apartmentId = residentData['apartmentName']
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    final result = await _visitorService.createDeliveryOTP(
      apartmentId: apartmentId,
      residentId: residentData['uid'],
      residentName: residentData['residentName'],
      apartmentNumber: residentData['apartmentNumber'],
      deliveryPerson: name,
      deliveryPhone: '0000000000', // Placeholder since we don't collect it
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      setState(() {
        generatedOTP = result['visitor'];
      });
    } else {
      _showError(result['message']);
    }
  }

  // Copy OTP to clipboard with message
  void _copyOTP() {
    final messages = [
      'Your OTP to show at the security gate while delivering is ${generatedOTP!.accessCode}.',
      'Hi! Please use this OTP at the gate: ${generatedOTP!.accessCode}',
      'Delivery OTP for security verification: ${generatedOTP!.accessCode}',
      'Your access code for gate entry is ${generatedOTP!.accessCode}. Valid for 24 hours.',
      'Gate entry code: ${generatedOTP!.accessCode}. Show this to security.',
      'Please share this OTP with delivery person: ${generatedOTP!.accessCode}',
    ];

    // Pick a random message
    final randomMessage =
        messages[DateTime.now().millisecond % messages.length];

    Clipboard.setData(ClipboardData(text: randomMessage));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied: "$randomMessage"'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Share OTP
  Future<void> _shareOTP() async {
    if (generatedOTP == null) return;

    String message =
        '''
🚚 SafeGate Delivery Pass

Your one-time delivery code for Apartment ${generatedOTP!.apartmentNumber}:

🔢 OTP: ${generatedOTP!.accessCode}

⚠️ This code expires after ONE use or after 24 hours.

Please show this code at the security gate when delivering.

Delivery Partner: ${generatedOTP!.visitorName}
''';

    await Share.share(message);
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
    super.dispose();
  }
}
