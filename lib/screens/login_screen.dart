import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'guard_home_screen.dart';
import 'welcome_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dynamic apartment names fetched from Firebase
  List<String> apartmentNames = [];
  bool isLoadingApartments = true;

  String? selectedApartmentName;
  final TextEditingController apartmentNameController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool rememberMe = false;
  bool showApartmentDropdown = false;
  List<String> filteredApartments = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _fetchApartments();
  }

  Future<void> _fetchApartments() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('apartments')
          .get();
      final List<String> fetchedApartments = snapshot.docs
          .map((doc) => doc['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toList();

      setState(() {
        apartmentNames = fetchedApartments;
        isLoadingApartments = false;
      });
    } catch (e) {
      // If fetching fails, set loading to false and keep empty list
      setState(() {
        isLoadingApartments = false;
      });
      // Log error for debugging (remove in production)
      debugPrint('Error fetching apartments: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    final savedApartmentName = await _secureStorage.read(
      key: 'saved_apartment_name',
    );
    final savedApartment = await _secureStorage.read(key: 'saved_apartment');
    final savedPassword = await _secureStorage.read(key: 'saved_password');
    final remember = await _secureStorage.read(key: 'remember_me');

    if (savedApartmentName != null &&
        savedApartment != null &&
        savedPassword != null &&
        remember == 'true') {
      setState(() {
        selectedApartmentName = savedApartmentName;
        apartmentNameController.text = savedApartmentName;
        apartmentController.text = savedApartment;
        passwordController.text = savedPassword;
        rememberMe = true;
      });
    }
  }

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'SafeGate',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Visitor Management System',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 50),
                // Apartment Name Input with Search
                Column(
                  children: [
                    TextField(
                      controller: apartmentNameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Apartment Name',
                        labelStyle: const TextStyle(fontSize: 18),
                        hintText: 'Type or select your apartment',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        prefixIcon: const Icon(Icons.business, size: 28),
                        suffixIcon: isLoadingApartments
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
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
                        if (!isLoadingApartments) {
                          setState(() {
                            if (!showApartmentDropdown) {
                              filteredApartments = apartmentNames;
                              showApartmentDropdown = true;
                            }
                          });
                        }
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
                        child: isLoadingApartments
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Loading apartments...'),
                                  ],
                                ),
                              )
                            : filteredApartments.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No apartments found'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredApartments.length,
                                itemBuilder: (context, index) {
                                  final apartment = filteredApartments[index];
                                  return ListTile(
                                    title: Text(apartment),
                                    onTap: () => _selectApartment(apartment),
                                    tileColor:
                                        selectedApartmentName == apartment
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
                TextField(
                  controller: apartmentController,
                  style: const TextStyle(fontSize: 18),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Apartment Number',
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
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(fontSize: 18),
                    hintText: 'Enter your password',
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
                const SizedBox(height: 16),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Remember Me', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Securely saves your credentials on this device',
                      /* child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),*/
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: isLoading ? null : _handleLogin,
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
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: isLoading ? null : _navigateToForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    String apartmentName = apartmentNameController.text.trim();
    String apartment = apartmentController.text.trim();
    String password = passwordController.text.trim();

    if (apartmentName.isEmpty) {
      _showErrorDialog('Please enter your apartment name');
      return;
    }

    if (apartment.isEmpty) {
      _showErrorDialog('Please enter your apartment number');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Please enter your password');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await _authService.loginResident(
      apartmentName: apartmentName,
      apartmentNumber: apartment,
      password: password,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Save credentials if Remember Me is checked
      if (rememberMe) {
        await _secureStorage.write(
          key: 'saved_apartment_name',
          value: apartmentName,
        );
        await _secureStorage.write(key: 'saved_apartment', value: apartment);
        await _secureStorage.write(key: 'saved_password', value: password);
        await _secureStorage.write(key: 'remember_me', value: 'true');
      } else {
        await _secureStorage.delete(key: 'saved_apartment_name');
        await _secureStorage.delete(key: 'saved_apartment');
        await _secureStorage.delete(key: 'saved_password');
        await _secureStorage.delete(key: 'remember_me');
      }

      // Check user role and profile completeness
      final userData = result['userData'];
      final role = userData['role'] ?? 'resident';

      // Check if profile is incomplete (missing required fields)
      bool isProfileIncomplete =
          userData['residentName'] == null ||
          userData['residentName'].toString().isEmpty ||
          userData['phoneNumber'] == null ||
          userData['phoneNumber'].toString().isEmpty ||
          userData['email'] == null ||
          userData['email'].toString().isEmpty;

      if (isProfileIncomplete) {
        // Redirect to welcome screen for profile completion
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              apartmentName: apartmentName,
              apartmentNumber: apartment,
              userData: userData,
            ),
          ),
        );
        return;
      }

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
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
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
    apartmentNameController.dispose();
    apartmentController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
