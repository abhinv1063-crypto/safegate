import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to login',
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Save apartment number and password for quick login
  Future<void> saveCredentials(String apartmentNumber, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_apartment', apartmentNumber);
    await prefs.setString('saved_password', password);
    await prefs.setBool('biometric_enabled', true);
  }

  /// Get saved apartment number
  Future<String?> getSavedApartmentNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_apartment');
  }

  /// Get saved password
  Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_password');
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  /// Enable biometric login
  Future<void> enableBiometric(String apartmentNumber, String password) async {
    await saveCredentials(apartmentNumber, password);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_apartment');
    await prefs.remove('saved_password');
    await prefs.setBool('biometric_enabled', false);
  }

  /// Clear all saved data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_apartment');
    await prefs.remove('saved_password');
    await prefs.remove('biometric_enabled');
  }
}
