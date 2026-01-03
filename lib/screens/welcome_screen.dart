import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'guard_home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String apartmentName;
  final String apartmentNumber;
  final Map<String, dynamic> userData;

  const WelcomeScreen({
    super.key,
    required this.apartmentName,
    required this.apartmentNumber,
    required this.userData,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    apartmentController.text = widget.apartmentNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Welcome to SafeGate'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.waving_hand, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to SafeGate!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete your profile setup to get started.',
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Full Name
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
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

              // Apartment Number (pre-filled, read-only)
              TextField(
                controller: apartmentController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.characters,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Apartment Number',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Your apartment number',
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

              // Phone Number
              TextField(
                controller: phoneController,
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: '10-digit number',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
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

              const SizedBox(height: 20),

              // New Password
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'New Password *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Create a strong password',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock, size: 28),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
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
              ),

              const SizedBox(height: 20),

              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Re-enter your password',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock_outline, size: 28),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
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
              ),

              const SizedBox(height: 32),

              // Complete Setup Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : _completeSetup,
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
                      : const Text('COMPLETE SETUP'),
                ),
              ),

              const SizedBox(height: 20),

              // Info text
              Center(
                child: Text(
                  'Your account will be created with the provided information.',
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

  Future<void> _completeSetup() async {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty) {
      _showErrorDialog('Please enter your full name');
      return;
    }

    if (phone.isEmpty || phone.length != 10) {
      _showErrorDialog('Please enter a valid 10-digit phone number');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters long');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _authService.completeResidentProfile(
        uid: widget.userData['uid'],
        apartmentName: widget.apartmentName,
        apartmentNumber: widget.apartmentNumber,
        residentName: name,
        phoneNumber: phone,
        email: email,
        newPassword: password,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        // Navigate to appropriate home screen based on role
        final role = widget.userData['role'] ?? 'resident';

        if (role == 'guard' || role == 'security') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GuardHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
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

  @override
  void dispose() {
    nameController.dispose();
    apartmentController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
