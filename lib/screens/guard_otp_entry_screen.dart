import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';

class GuardOTPEntryScreen extends StatefulWidget {
  const GuardOTPEntryScreen({super.key});

  @override
  State<GuardOTPEntryScreen> createState() => _GuardOTPEntryScreenState();
}

class _GuardOTPEntryScreenState extends State<GuardOTPEntryScreen> {
  final VisitorService _visitorService = VisitorService();
  final TextEditingController otpController = TextEditingController();
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Enter OTP'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the 6-digit OTP shown by the delivery person',
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

              const SizedBox(height: 40),

              Text(
                'Delivery OTP',
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const SizedBox(height: 10),

              Text(
                'Ask the delivery person for their 6-digit code',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 30),

              // OTP Input Field
              TextField(
                controller: otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    color: Colors.grey[300],
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange[300]!,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange[700]!,
                      width: 3,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    _verifyOTP();
                  }
                },
              ),

              const SizedBox(height: 30),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: isVerifying ? null : _verifyOTP,
                  icon: isVerifying
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 28),
                  label: Text(
                    isVerifying ? 'VERIFYING...' : 'VERIFY OTP',
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
        ),
      ),
    );
  }

  /*  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildNumberButton(''),
            _buildNumberButton('0'),
            _buildNumberButton('⌫', isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number, {bool isBackspace = false}) {
    if (number.isEmpty) {
      return const Expanded(child: SizedBox());
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isBackspace) {
                if (otpController.text.isNotEmpty) {
                  otpController.text = otpController.text.substring(
                    0,
                    otpController.text.length - 1,
                  );
                }
              } else {
                if (otpController.text.length < 6) {
                  otpController.text += number;
                  if (otpController.text.length == 6) {
                    _verifyOTP();
                  }
                }
              }
            },
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
*/
  Future<void> _verifyOTP() async {
    String otp = otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter a 6-digit OTP');
      return;
    }

    setState(() {
      isVerifying = true;
    });

    final result = await _visitorService.verifyAccessCode(otp);

    setState(() {
      isVerifying = false;
    });

    if (result['success']) {
      final VisitorModel visitor = result['visitor'];
      if (mounted) {
        _showVisitorDetails(visitor);
      }
    } else {
      _showError(result['message']);
    }
  }

  void _showVisitorDetails(VisitorModel visitor) {
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
              _buildInfoRow('Delivery Person', visitor.visitorName),
              const Divider(height: 16),
              _buildInfoRow('Apartment', visitor.apartmentNumber),
              const Divider(height: 16),
              _buildInfoRow('Resident', visitor.residentName),
              const Divider(height: 16),
              _buildInfoRow('Phone', visitor.visitorPhone),
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
                        'OTP has been used and deactivated',
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
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              otpController.clear();
              setState(() {});
            },
            child: const Text('VERIFY NEXT'),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 32),
            const SizedBox(width: 10),
            const Text('Invalid OTP'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              otpController.clear();
            },
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
