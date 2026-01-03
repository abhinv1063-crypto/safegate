import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore database instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new resident
  /// Creates both an authentication account and a database record
  Future<Map<String, dynamic>> registerResident({
    required String apartmentName,
    required String apartmentNumber,
    required String password,
    required String residentName,
    required String phoneNumber,
  }) async {
    try {
      // Validate inputs
      if (apartmentName.isEmpty) {
        return {'success': false, 'message': 'Apartment name is required'};
      }

      if (apartmentNumber.isEmpty) {
        return {'success': false, 'message': 'Apartment number is required'};
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      if (residentName.isEmpty) {
        return {'success': false, 'message': 'Name is required'};
      }

      if (phoneNumber.isEmpty) {
        return {'success': false, 'message': 'Phone number is required'};
      }

      // Get apartment ID for collection lookup
      String apartmentId = apartmentName.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      // Check if apartment number already exists in this apartment
      final existingApartment = await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .where('apartmentNumber', isEqualTo: apartmentNumber.toUpperCase())
          .get();

      if (existingApartment.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'This apartment number is already registered in $apartmentName',
        };
      }

      // Convert apartment name to email domain format
      String apartmentDomain = apartmentName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      ); // Remove spaces and special chars

      // Create email in new format: apartmentNumber@apartmentDomain.app
      String email =
          '${apartmentNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@${apartmentDomain}.app';

      // Create authentication account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create resident profile in apartment-specific collection
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'apartmentName': apartmentName,
            'apartmentNumber': apartmentNumber.toUpperCase(),
            'residentName': residentName,
            'phoneNumber': phoneNumber,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'resident', // resident, guard, or admin
            'isActive': true,
          });

      // Also create a global reference
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'apartmentName': apartmentName,
        'apartmentNumber': apartmentNumber.toUpperCase(),
        'residentName': residentName,
        'phoneNumber': phoneNumber,
        'email': email,
        'profileRef':
            '/apartments/$apartmentId/users/${userCredential.user!.uid}',
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'resident',
        'isActive': true,
      });

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      String message = 'Registration failed';

      if (e.code == 'email-already-in-use') {
        message = 'This apartment number is already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Check your internet connection';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Login existing resident
  Future<Map<String, dynamic>> loginResident({
    required String apartmentName,
    required String apartmentNumber,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (apartmentName.isEmpty) {
        return {'success': false, 'message': 'Apartment name is required'};
      }

      if (apartmentNumber.isEmpty) {
        return {'success': false, 'message': 'Apartment number is required'};
      }

      if (password.isEmpty) {
        return {'success': false, 'message': 'Password is required'};
      }

      // Convert apartment name to email domain format
      String apartmentDomain = apartmentName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      ); // Remove spaces and special chars

      // Create email in new format: apartmentNumber@apartmentDomain.app
      String email =
          '${apartmentNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@${apartmentDomain}.app';

      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get apartment ID for collection lookup
      String apartmentId = apartmentName.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      // Get resident data from apartment-specific collection
      DocumentSnapshot residentDoc = await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!residentDoc.exists) {
        // Sign out if profile doesn't exist in apartment
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Profile not found in $apartmentName. Please check your apartment selection or contact admin.',
          'debug': 'UID: ${userCredential.user!.uid}, Apartment: $apartmentId',
        };
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userCredential.user,
        'userData': {
          ...residentDoc.data() as Map<String, dynamic>,
          'apartmentName': apartmentName, // Add apartment name from login
        },
      };
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'Apartment not registered. Please create an account first.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid apartment number or password';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Check your internet connection';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Try again later';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get resident data
  Future<Map<String, dynamic>?> getResidentData() async {
    try {
      if (currentUser == null) return null;

      // First, try to get user data from global users collection
      DocumentSnapshot globalDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (globalDoc.exists) {
        final globalData = globalDoc.data() as Map<String, dynamic>;
        final apartmentName = globalData['apartmentName'];

        if (apartmentName != null) {
          // Get apartment ID and fetch from apartment-specific collection
          String apartmentId = apartmentName.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            '',
          );

          DocumentSnapshot apartmentDoc = await _firestore
              .collection('apartments')
              .doc(apartmentId)
              .collection('users')
              .doc(currentUser!.uid)
              .get();

          if (apartmentDoc.exists) {
            return apartmentDoc.data() as Map<String, dynamic>;
          }
        }

        // Fallback to global data if apartment data not found
        return globalData;
      }

      // Legacy fallback - try old residents collection
      DocumentSnapshot legacyDoc = await _firestore
          .collection('residents')
          .doc(currentUser!.uid)
          .get();

      if (legacyDoc.exists) {
        return legacyDoc.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error getting resident data: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Complete resident profile (for first-time users)
  Future<Map<String, dynamic>> completeResidentProfile({
    required String uid,
    required String apartmentName,
    required String apartmentNumber,
    required String residentName,
    required String phoneNumber,
    required String email,
    required String newPassword,
  }) async {
    try {
      // Validate inputs
      if (apartmentName.isEmpty) {
        return {'success': false, 'message': 'Apartment name is required'};
      }

      if (residentName.isEmpty) {
        return {'success': false, 'message': 'Name is required'};
      }

      if (phoneNumber.isEmpty) {
        return {'success': false, 'message': 'Phone number is required'};
      }

      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        return {'success': false, 'message': 'Valid email is required'};
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      // Get apartment ID for collection lookup
      String apartmentId = apartmentName.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      // Update the resident profile in apartment-specific collection
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .doc(uid)
          .update({
            'apartmentName': apartmentName,
            'apartmentNumber': apartmentNumber.toUpperCase(),
            'residentName': residentName,
            'phoneNumber': phoneNumber,
            'email': email,
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Also update the global users collection reference
      await _firestore.collection('users').doc(uid).update({
        'apartmentName': apartmentName,
        'apartmentNumber': apartmentNumber.toUpperCase(),
        'residentName': residentName,
        'phoneNumber': phoneNumber,
        'email': email,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update password if provided
      if (newPassword.isNotEmpty) {
        await _auth.currentUser!.updatePassword(newPassword);
      }

      return {'success': true, 'message': 'Profile completed successfully!'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to complete profile: ${e.toString()}',
      };
    }
  }

  /// Reset password by sending email
  Future<Map<String, dynamic>> resetPassword({
    required String apartmentName,
    required String apartmentNumber,
    required String email,
  }) async {
    try {
      // Validate inputs
      if (apartmentName.isEmpty) {
        return {'success': false, 'message': 'Apartment name is required'};
      }

      if (apartmentNumber.isEmpty) {
        return {'success': false, 'message': 'Apartment number is required'};
      }

      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        return {'success': false, 'message': 'Valid email is required'};
      }

      // Find resident by apartment number and email in apartment-specific collection
      String apartmentId = apartmentName.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      print(
        'Reset password - Apartment: $apartmentName, ID: $apartmentId, Number: $apartmentNumber, Email: $email',
      );

      final residentQuery = await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .where('apartmentNumber', isEqualTo: apartmentNumber.toUpperCase())
          .where('email', isEqualTo: email)
          .get();

      print('Reset password - Found ${residentQuery.docs.length} documents');

      // If not found in specific apartment, try searching across all apartments
      if (residentQuery.docs.isEmpty) {
        print(
          'Reset password - Not found in specific apartment, searching all apartments',
        );

        // Get all apartment documents
        final apartmentsSnapshot = await _firestore
            .collection('apartments')
            .get();

        for (final apartmentDoc in apartmentsSnapshot.docs) {
          final apartmentUsers = await apartmentDoc.reference
              .collection('users')
              .where(
                'apartmentNumber',
                isEqualTo: apartmentNumber.toUpperCase(),
              )
              .where('email', isEqualTo: email)
              .get();

          if (apartmentUsers.docs.isNotEmpty) {
            print('Reset password - Found in apartment: ${apartmentDoc.id}');
            // Update the query to use the found documents
            final updatedQuery = apartmentUsers;
            // Continue with the found user
            final residentDoc = updatedQuery.docs.first;
            final residentData = residentDoc.data();

            // Generate auth email from the actual apartment name stored in the document
            final storedApartmentName =
                residentData['apartmentName'] ?? apartmentName;
            final apartmentDomain = storedApartmentName
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '');
            final authEmail =
                '${apartmentNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@${apartmentDomain}.app';

            print('Reset password - Auth email: $authEmail');

            // Generate a new temporary password
            String tempPassword = _generateTempPassword();

            // Create password reset request
            await _firestore.collection('password_resets').add({
              'apartmentNumber': apartmentNumber.toUpperCase(),
              'email': email,
              'apartmentName': storedApartmentName,
              'tempPassword': tempPassword,
              'createdAt': FieldValue.serverTimestamp(),
              'used': false,
            });

            return {
              'success': true,
              'message':
                  'Password reset request submitted. Check your email for the new password.',
            };
          }
        }

        // If still not found, check if user exists but hasn't completed profile
        for (final apartmentDoc in apartmentsSnapshot.docs) {
          final apartmentUsers = await apartmentDoc.reference
              .collection('users')
              .where(
                'apartmentNumber',
                isEqualTo: apartmentNumber.toUpperCase(),
              )
              .get();

          if (apartmentUsers.docs.isNotEmpty) {
            final doc = apartmentUsers.docs.first;
            final data = doc.data();
            print(
              'Reset password - Found user without email match. Stored email: ${data['email']}, profileCompleted: ${data['profileCompleted']}',
            );
          }
        }

        return {
          'success': false,
          'message':
              'No account found with these details. Please check your information.',
        };
      }

      // Generate a new temporary password
      String tempPassword = _generateTempPassword();

      // Get the resident document
      final residentDoc = residentQuery.docs.first;
      final residentData = residentDoc.data();

      // Update password in Firebase Auth
      // First, we need to sign in as this user to update password
      String authEmail = residentData['email'] ?? '';
      if (authEmail.isEmpty) {
        return {
          'success': false,
          'message': 'Unable to reset password. Please contact support.',
        };
      }

      // For security, we'll send an email with instructions instead of auto-resetting
      // In a real app, you'd use Firebase Functions to send emails
      // For now, we'll simulate this by updating a reset request in Firestore

      await _firestore.collection('password_resets').add({
        'apartmentNumber': apartmentNumber.toUpperCase(),
        'email': email,
        'apartmentName': apartmentName,
        'tempPassword': tempPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'used': false,
      });

      return {
        'success': true,
        'message':
            'Password reset request submitted. Check your email for the new password.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reset password: ${e.toString()}',
      };
    }
  }

  /// Generate a temporary password
  String _generateTempPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing O, 0, I, 1
    Random random = Random.secure();
    return 'SG-' + // Prefixed with SafeGate identifier
        List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Update FCM token for the current resident
  Future<void> updateFCMToken(String token) async {
    try {
      if (currentUser == null) return;

      // First, try to get user data from global users collection to find apartment
      DocumentSnapshot globalDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (globalDoc.exists) {
        final globalData = globalDoc.data() as Map<String, dynamic>;
        final apartmentName = globalData['apartmentName'];

        if (apartmentName != null) {
          // Update FCM token in apartment-specific collection
          String apartmentId = apartmentName.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            '',
          );

          await _firestore
              .collection('apartments')
              .doc(apartmentId)
              .collection('users')
              .doc(currentUser!.uid)
              .update({
                'fcmToken': token,
                'lastTokenUpdate': FieldValue.serverTimestamp(),
              });

          // Also update global collection
          await globalDoc.reference.update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });

          return;
        }
      }

      // Fallback - try old residents collection for backward compatibility
      try {
        await _firestore.collection('residents').doc(currentUser!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating FCM token in legacy collection: $e');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
