import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();

  // Pre-defined apartment names (same as login screen)
  final List<String> apartmentNames = [
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

  String? selectedApartmentName;
  final TextEditingController apartmentNameController = TextEditingController();
  final TextEditingController apartmentNumberController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  bool showApartmentDropdown = false;
  List<String> filteredApartments = [];

  void _filterApartments(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredApartments = apartmentNames;
      } else {
        filteredApartments = apartmentNames
            .where(
              (apartment) =>
                  apartment.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      showApartmentDropdown = query.isNotEmpty;
    });
  }

  void _selectApartment(String apartment) {
    setState(() {
      selectedApartmentName = apartment;
      apartmentNameController.text = apartment;
      showApartmentDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock_reset, size: 48, color: Colors.orange[700]),
                    const SizedBox(height: 16),
                    Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details below and we\'ll send a new password to your email.',
                      style: TextStyle(fontSize: 16, color: Colors.orange[800]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Apartment Name Input with Search
              Column(
                children: [
                  TextField(
                    controller: apartmentNameController,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Apartment Name *',
                      labelStyle: const TextStyle(fontSize: 18),
                      hintText: 'Type or select your apartment',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.business, size: 28),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showApartmentDropdown
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            if (showApartmentDropdown) {
                              showApartmentDropdown = false;
                            } else {
                              filteredApartments = apartmentNames;
                              showApartmentDropdown = true;
                            }
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                    onChanged: _filterApartments,
                    onTap: () {
                      setState(() {
                        if (!showApartmentDropdown) {
                          filteredApartments = apartmentNames;
                          showApartmentDropdown = true;
                        }
                      });
                    },
                  ),
                  if (showApartmentDropdown)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredApartments.length,
                        itemBuilder: (context, index) {
                          final apartment = filteredApartments[index];
                          return ListTile(
                            title: Text(apartment),
                            onTap: () => _selectApartment(apartment),
                            tileColor: selectedApartmentName == apartment
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Apartment Number
              TextField(
                controller: apartmentNumberController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Apartment Number *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'e.g., A-101',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
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

              // Email
              TextField(
                controller: emailController,
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'your.email@example.com',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.email, size: 28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : _resetPassword,
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text('RESET PASSWORD'),
                ),
              ),

              const SizedBox(height: 20),

              // Info text
              Center(
                child: Text(
                  'A new password will be sent to your email address.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    String apartmentName = apartmentNameController.text.trim();
    String apartmentNumber = apartmentNumberController.text.trim();
    String email = emailController.text.trim();

    // Validation
    if (apartmentName.isEmpty) {
      _showErrorDialog('Please enter your apartment name');
      return;
    }

    if (apartmentNumber.isEmpty) {
      _showErrorDialog('Please enter your apartment number');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _authService.resetPassword(
        apartmentName: apartmentName,
        apartmentNumber: apartmentNumber,
        email: email,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        _showSuccessDialog(result['message']);
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text('Password Reset'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login
            },
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    apartmentNameController.dispose();
    apartmentNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
