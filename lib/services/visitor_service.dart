import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor_model.dart';
import 'notification_service.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a unique QR code for a visitor
  String _generateQRCode() {
    // Generate a unique 16-character code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      16,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit number
  }

  /// Create a guest visitor invitation (QR Code)
  Future<Map<String, dynamic>> createGuestInvitation({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String apartmentNumber,
    required String visitorName,
    required String visitorPhone,
    required DateTime validFrom,
    required DateTime validUntil,
    String? vehiclePlateNumber,
  }) async {
    try {
      // Validate inputs
      if (visitorName.isEmpty) {
        return {'success': false, 'message': 'Visitor name is required'};
      }

      if (visitorPhone.isEmpty || visitorPhone.length != 10) {
        return {
          'success': false,
          'message': 'Valid 10-digit phone number required',
        };
      }

      if (validFrom.isAfter(validUntil)) {
        return {
          'success': false,
          'message': 'Valid from time must be before valid until time',
        };
      }

      // Generate unique QR code
      String qrCode = _generateQRCode();

      // Create visitor document
      String visitorId = _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc()
          .id;

      VisitorModel visitor = VisitorModel(
        id: visitorId,
        residentId: residentId,
        residentName: residentName,
        apartmentNumber: apartmentNumber,
        visitorName: visitorName,
        visitorPhone: visitorPhone,
        visitorType: 'guest',
        accessCode: qrCode,
        validFrom: validFrom,
        validUntil: validUntil,
        isActive: true,
        vehiclePlateNumber: vehiclePlateNumber,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .set(visitor.toJson());

      return {
        'success': true,
        'message': 'Invitation created successfully',
        'visitor': visitor,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating invitation: ${e.toString()}',
      };
    }
  }

  /// Create a delivery OTP
  Future<Map<String, dynamic>> createDeliveryOTP({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String apartmentNumber,
    required String deliveryPerson,
    required String deliveryPhone,
  }) async {
    try {
      // Validate inputs
      if (deliveryPerson.isEmpty) {
        return {
          'success': false,
          'message': 'Delivery person name is required',
        };
      }

      if (deliveryPhone.isEmpty || deliveryPhone.length != 10) {
        return {
          'success': false,
          'message': 'Valid 10-digit phone number required',
        };
      }

      // Generate OTP
      String otp = _generateOTP();

      // Create visitor document
      String visitorId = _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc()
          .id;

      // OTP valid for 24 hours
      DateTime now = DateTime.now();
      DateTime validUntil = now.add(const Duration(hours: 24));

      VisitorModel visitor = VisitorModel(
        id: visitorId,
        residentId: residentId,
        residentName: residentName,
        apartmentNumber: apartmentNumber,
        visitorName: deliveryPerson,
        visitorPhone: deliveryPhone,
        visitorType: 'delivery',
        accessCode: otp,
        validFrom: now,
        validUntil: validUntil,
        isActive: true,
        createdAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .set(visitor.toJson());

      return {
        'success': true,
        'message': 'OTP generated successfully',
        'visitor': visitor,
        'otp': otp,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating OTP: ${e.toString()}',
      };
    }
  }

  /// Get all active visitors for a resident
  Stream<List<VisitorModel>> getActiveVisitors(String residentId) {
    return _firestore
        .collection('visitors')
        .where('residentId', isEqualTo: residentId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VisitorModel.fromJson(doc.data());
          }).toList();
        });
  }

  /// Get visitor history for a resident
  Stream<List<VisitorModel>> getVisitorHistory(String residentId) {
    return _firestore
        .collection('visitors')
        .where('residentId', isEqualTo: residentId)
        .snapshots()
        .map((snapshot) {
          // Get all visitors and sort in memory
          final allVisitors = snapshot.docs.map((doc) {
            return VisitorModel.fromJson(doc.data());
          }).toList();

          // Sort by created date (newest first) and limit to 50
          allVisitors.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return allVisitors.take(50).toList();
        });
  }

  /// Mark visitor as departed (deactivate QR/OTP)
  Future<Map<String, dynamic>> markDeparted(
    String apartmentId,
    String visitorId,
  ) async {
    try {
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .update({
            'isActive': false,
            'departureTime': FieldValue.serverTimestamp(),
          });

      return {'success': true, 'message': 'Visitor marked as departed'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error marking departure: ${e.toString()}',
      };
    }
  }

  /// Update visitor validity time
  Future<Map<String, dynamic>> updateVisitorValidity({
    required String apartmentId,
    required String visitorId,
    required DateTime validFrom,
    required DateTime validUntil,
  }) async {
    try {
      if (validFrom.isAfter(validUntil)) {
        return {
          'success': false,
          'message': 'Valid from time must be before valid until time',
        };
      }

      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .update({
            'validFrom': Timestamp.fromDate(validFrom),
            'validUntil': Timestamp.fromDate(validUntil),
            'isActive': true, // Reactivate if it was expired
          });

      return {'success': true, 'message': 'Validity time updated successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating validity: ${e.toString()}',
      };
    }
  }

  /// Verify access code (for security guard)
  Future<Map<String, dynamic>> verifyAccessCode(String code) async {
    try {
      // Search for visitor with this code
      QuerySnapshot snapshot = await _firestore
          .collection('visitors')
          .where('accessCode', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Invalid or expired code'};
      }

      VisitorModel visitor = VisitorModel.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );

      // Check if code is still valid time-wise
      DateTime now = DateTime.now();
      if (now.isBefore(visitor.validFrom)) {
        return {
          'success': false,
          'message': 'Code not yet valid. Valid from: ${visitor.validFrom}',
        };
      }

      if (now.isAfter(visitor.validUntil)) {
        return {'success': false, 'message': 'Code has expired'};
      }

      // Mark as arrived if first time
      if (!visitor.hasArrived) {
        await _firestore.collection('visitors').doc(visitor.id).update({
          'hasArrived': true,
          'arrivalTime': FieldValue.serverTimestamp(),
        });

        // For delivery OTP, auto-deactivate after single use
        if (visitor.visitorType == 'delivery') {
          await _firestore.collection('visitors').doc(visitor.id).update({
            'isActive': false,
          });
        }
      }

      return {'success': true, 'message': 'Access granted', 'visitor': visitor};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying code: ${e.toString()}',
      };
    }
  }

  /// Delete a visitor invitation
  Future<Map<String, dynamic>> deleteVisitor(
    String apartmentId,
    String visitorId,
  ) async {
    try {
      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .delete();
      return {'success': true, 'message': 'Invitation deleted'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting invitation: ${e.toString()}',
      };
    }
  }

  /// Create a frequent visitor
  Future<Map<String, dynamic>> createFrequentVisitor({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String apartmentNumber,
    required String visitorName,
    required String visitorPhone,
    required String visitorRole,
  }) async {
    try {
      if (visitorName.isEmpty) {
        return {'success': false, 'message': 'Visitor name is required'};
      }

      if (visitorPhone.isEmpty || visitorPhone.length != 10) {
        return {
          'success': false,
          'message': 'Valid 10-digit phone number required',
        };
      }

      String qrCode = _generateQRCode();
      String visitorId = _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc()
          .id;

      DateTime now = DateTime.now();
      DateTime validUntil = now.add(const Duration(days: 365));

      VisitorModel visitor = VisitorModel(
        id: visitorId,
        residentId: residentId,
        residentName: residentName,
        apartmentNumber: apartmentNumber,
        visitorName: '$visitorName ($visitorRole)',
        visitorPhone: visitorPhone,
        visitorType: 'frequent',
        accessCode: qrCode,
        validFrom: now,
        validUntil: validUntil,
        isActive: true,
        createdAt: now,
      );

      await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .doc(visitorId)
          .set(visitor.toJson());

      return {
        'success': true,
        'message': 'Frequent visitor added successfully',
        'visitor': visitor,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding frequent visitor: ${e.toString()}',
      };
    }
  }

  /// Get all frequent visitors for a resident
  Stream<List<VisitorModel>> getFrequentVisitors(String residentId) {
    return _firestore
        .collection('visitors')
        .where('residentId', isEqualTo: residentId)
        .where('visitorType', isEqualTo: 'frequent')
        .snapshots()
        .map((snapshot) {
          final allVisitors = snapshot.docs.map((doc) {
            return VisitorModel.fromJson(doc.data());
          }).toList();

          allVisitors.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return allVisitors;
        });
  }

  /// Toggle frequent visitor active status
  Future<Map<String, dynamic>> toggleFrequentVisitor(
    String visitorId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('visitors').doc(visitorId).update({
        'isActive': isActive,
      });

      return {
        'success': true,
        'message': isActive ? 'Visitor activated' : 'Visitor deactivated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating visitor: ${e.toString()}',
      };
    }
  }

  /// Check for visitors that are about to expire and send notifications
  /// This should be called periodically (e.g., every hour)
  Future<void> checkAndNotifyExpiringVisitors() async {
    try {
      final now = DateTime.now();
      final warningTime = now.add(
        const Duration(hours: 2),
      ); // Notify 2 hours before expiry

      // Get all active visitors that expire within the next 2 hours
      final expiringVisitors = await _firestore
          .collection('visitors')
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: now)
          .where('validUntil', isLessThanOrEqualTo: warningTime)
          .get();

      for (final doc in expiringVisitors.docs) {
        final visitor = VisitorModel.fromJson(doc.data());
        await _sendExpiryNotification(visitor);
      }
    } catch (e) {
      print('Error checking expiring visitors: $e');
    }
  }

  /// Send expiry notification to resident
  Future<void> _sendExpiryNotification(VisitorModel visitor) async {
    try {
      // For now, we'll show a local notification to the resident
      // In production, this would be sent via Firebase Cloud Functions

      // Get resident's FCM token from apartment-specific collection
      // First, get user data from global users collection to find apartment
      final globalDoc = await _firestore
          .collection('users')
          .doc(visitor.residentId)
          .get();

      if (!globalDoc.exists) return;

      final globalData = globalDoc.data()!;
      final apartmentName = globalData['apartmentName'];

      if (apartmentName == null) return;

      String apartmentId = apartmentName.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      final residentDoc = await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('users')
          .doc(visitor.residentId)
          .get();

      if (!residentDoc.exists) return;

      final residentData = residentDoc.data();
      final fcmToken = residentData?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        // Fallback: show local notification if no FCM token
        final notificationService = NotificationService();
        await notificationService.showVisitorExpiryNotification(
          visitorName: visitor.visitorName,
          visitorId: visitor.id,
          validUntil: visitor.validUntil,
        );
        return;
      }

      // Try to send FCM notification
      final notificationService = NotificationService();
      final success = await notificationService.sendFCMNotification(
        token: fcmToken,
        title: '🚨 Visitor QR Expiring Soon',
        body:
            '${visitor.visitorName}\'s access expires in less than 2 hours. Mark as departed or extend validity.',
        data: {
          'type': 'visitor_expiry',
          'visitorId': visitor.id,
          'visitorName': visitor.visitorName,
          'validUntil': visitor.validUntil.toIso8601String(),
        },
      );

      // If FCM fails, fallback to local notification
      if (!success) {
        await notificationService.showVisitorExpiryNotification(
          visitorName: visitor.visitorName,
          visitorId: visitor.id,
          validUntil: visitor.validUntil,
        );
      }
    } catch (e) {
      print('Error sending expiry notification: $e');
    }
  }

  /// Update vehicle number for a visitor
  Future<bool> updateVehicleNumber(
    String visitorId,
    String vehicleNumber,
  ) async {
    try {
      await _firestore.collection('visitors').doc(visitorId).update({
        'vehiclePlateNumber': vehicleNumber,
      });
      return true;
    } catch (e) {
      print('Error updating vehicle number: $e');
      return false;
    }
  }
}
