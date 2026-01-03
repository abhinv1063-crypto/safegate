import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../services/biometric_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

final AuthService _authService = AuthService();
final BiometricService _biometricService = BiometricService(); // ADD THIS LINE

class _RegisterScreenState extends State<RegisterScreen> {
  // Authentication service
  final AuthService _authService = AuthService();

  // Pre-defined apartment names
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
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // To show/hide passwords
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  // To show loading spinner
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
        title: const Text('Create Account'),
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
              // Welcome text
              Text(
                'Welcome to SafeGate!',
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const SizedBox(height: 10),

              Text(
                'Please fill in your details to create an account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 30),

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

              // Apartment Number Input
              TextField(
                controller: apartmentController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Apartment Number *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'e.g., A-101, B-205',
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

              // Full Name Input
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'e.g., John Doe',
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

              // Phone Number Input
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
                  hintText: '10-digit mobile number',
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

              // Password Input
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Minimum 6 characters',
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

              // Confirm Password Input
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: 'Re-enter password',
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

              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : _handleRegister,
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
                      : const Text('CREATE ACCOUNT'),
                ),
              ),

              const SizedBox(height: 20),

              // Already have account text
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle registration
  Future<void> _handleRegister() async {
    // Get text from fields
    String apartmentName = apartmentNameController.text.trim();
    String apartment = apartmentController.text.trim();
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // Validate inputs
    if (apartmentName.isEmpty) {
      _showErrorDialog('Please enter your apartment name');
      return;
    }

    if (apartment.isEmpty) {
      _showErrorDialog('Please enter your apartment number');
      return;
    }

    if (name.isEmpty) {
      _showErrorDialog('Please enter your full name');
      return;
    }

    if (phone.isEmpty) {
      _showErrorDialog('Please enter your phone number');
      return;
    }

    if (phone.length != 10) {
      _showErrorDialog('Phone number must be 10 digits');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Please enter a password');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showErrorDialog('Please confirm your password');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    // Show loading
    setState(() {
      isLoading = true;
    });

    // Call authentication service
    final result = await _authService.registerResident(
      apartmentName: apartmentName,
      apartmentNumber: apartment,
      password: password,
      residentName: name,
      phoneNumber: phone,
    );

    // Hide loading
    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Registration successful! Auto-login the user
      if (mounted) {
        // Show success message briefly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account created successfully!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to home
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        });
      }
    } else {
      // Registration failed
      _showErrorDialog(result['message']);
    }
  }

  // Show error popup
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

  // Show success popup
  void _showSuccessDialog(String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text('Success'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Offer biometric setup after registration
  void _offerBiometricSetup(String apartment, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.fingerprint,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('Enable Fingerprint?'),
          ],
        ),
        content: const Text(
          'Would you like to enable fingerprint/face recognition for faster login?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('NOT NOW', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () async {
              await _biometricService.enableBiometric(apartment, password);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('ENABLE', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    apartmentNameController.dispose();
    apartmentController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
