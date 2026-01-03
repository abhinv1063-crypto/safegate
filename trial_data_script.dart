import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to create trial data for apartments
/// Run this script to populate sample data for testing apartment-specific functionality
void main() async {
  final firestore = FirebaseFirestore.instance;

  // Trial data for Green Valley Apartments
  await _createTrialDataForApartment(
    firestore,
    'greenvalleyapartments',
    'Green Valley Apartments',
  );

  // Trial data for Palm Grove Apartments
  await _createTrialDataForApartment(
    firestore,
    'palmgroveapartments',
    'Palm Grove Apartments',
  );

  print('Trial data creation completed!');
}

Future<void> _createTrialDataForApartment(
  FirebaseFirestore firestore,
  String apartmentId,
  String apartmentName,
) async {
  print('Creating trial data for $apartmentName...');

  // Create sample residents
  final residents = [
    {
      'apartmentNumber': 'A-101',
      'residentName': 'Rajesh Kumar',
      'phoneNumber': '9876543210',
      'email': 'a101@$apartmentId.app',
    },
    {
      'apartmentNumber': 'A-102',
      'residentName': 'Priya Sharma',
      'phoneNumber': '9876543211',
      'email': 'a102@$apartmentId.app',
    },
    {
      'apartmentNumber': 'B-201',
      'residentName': 'Amit Singh',
      'phoneNumber': '9876543212',
      'email': 'b201@$apartmentId.app',
    },
  ];

  for (final resident in residents) {
    final email = resident['email'] as String;
    final userId = email.replaceAll('@', '_').replaceAll('.', '_');

    await firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('users')
        .doc(userId)
        .set({
          'uid': userId,
          'apartmentName': apartmentName,
          'apartmentNumber': resident['apartmentNumber'],
          'residentName': resident['residentName'],
          'phoneNumber': resident['phoneNumber'],
          'email': email,
          'role': 'resident',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // Also create global reference
    await firestore.collection('users').doc(userId).set({
      'apartmentName': apartmentName,
      'apartmentNumber': resident['apartmentNumber'],
      'residentName': resident['residentName'],
      'phoneNumber': resident['phoneNumber'],
      'email': email,
      'profileRef': '/apartments/$apartmentId/users/$userId',
      'role': 'resident',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create sample guard
  final guardEmail = 'guard@$apartmentId.app';
  final guardUserId = guardEmail.replaceAll('@', '_').replaceAll('.', '_');

  await firestore
      .collection('apartments')
      .doc(apartmentId)
      .collection('users')
      .doc(guardUserId)
      .set({
        'uid': guardUserId,
        'apartmentName': apartmentName,
        'apartmentNumber': 'GUARD',
        'residentName': 'Security Guard',
        'phoneNumber': '9876543219',
        'email': guardEmail,
        'role': 'guard',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

  await firestore.collection('users').doc(guardUserId).set({
    'apartmentName': apartmentName,
    'apartmentNumber': 'GUARD',
    'residentName': 'Security Guard',
    'phoneNumber': '9876543219',
    'email': guardEmail,
    'profileRef': '/apartments/$apartmentId/users/$guardUserId',
    'role': 'guard',
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Create sample visitors
  final visitors = [
    {
      'residentId': residents[0]['email']!
          .replaceAll('@', '_')
          .replaceAll('.', '_'),
      'residentName': residents[0]['residentName'],
      'apartmentNumber': residents[0]['apartmentNumber'],
      'visitorName': 'Delivery Person',
      'visitorPhone': '9876543220',
      'visitorType': 'delivery',
      'accessCode': 'DEL123456',
      'isActive': true,
      'hasArrived': false,
    },
    {
      'residentId': residents[1]['email']!
          .replaceAll('@', '_')
          .replaceAll('.', '_'),
      'residentName': residents[1]['residentName'],
      'apartmentNumber': residents[1]['apartmentNumber'],
      'visitorName': 'John Doe',
      'visitorPhone': '9876543221',
      'visitorType': 'guest',
      'accessCode': 'GUEST123456',
      'isActive': true,
      'hasArrived': true,
    },
  ];

  for (final visitor in visitors) {
    final visitorId = firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('visitors')
        .doc()
        .id;

    await firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('visitors')
        .doc(visitorId)
        .set({
          'id': visitorId,
          ...visitor,
          'validFrom': FieldValue.serverTimestamp(),
          'validUntil': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Create sample visitor requests
  final requests = [
    {
      'visitorName': 'Jane Smith',
      'visitorPhone': '9876543222',
      'apartmentNumber': residents[2]['apartmentNumber'],
      'residentId': residents[2]['email']!
          .replaceAll('@', '_')
          .replaceAll('.', '_'),
      'residentName': residents[2]['residentName'],
      'guardId': guardUserId,
      'guardName': 'Security Guard',
      'status': 'pending',
      'remarks': 'Friend visiting',
    },
  ];

  for (final request in requests) {
    final requestId = firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('visitor_requests')
        .doc()
        .id;

    await firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('visitor_requests')
        .doc(requestId)
        .set({
          'id': requestId,
          ...request,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  print('Trial data created for $apartmentName');
}
