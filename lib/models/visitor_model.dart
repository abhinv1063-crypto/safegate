import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorModel {
  final String id;
  final String residentId;
  final String residentName;
  final String apartmentNumber;
  final String visitorName;
  final String visitorPhone;
  final String visitorType; // 'guest', 'delivery', 'frequent'
  final String accessCode; // QR code data or OTP
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final bool hasArrived;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final String? vehiclePlateNumber;
  final DateTime createdAt;

  VisitorModel({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.apartmentNumber,
    required this.visitorName,
    required this.visitorPhone,
    required this.visitorType,
    required this.accessCode,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.hasArrived = false,
    this.arrivalTime,
    this.departureTime,
    this.vehiclePlateNumber,
    required this.createdAt,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'residentName': residentName,
      'apartmentNumber': apartmentNumber,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'visitorType': visitorType,
      'accessCode': accessCode,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
      'hasArrived': hasArrived,
      'arrivalTime': arrivalTime != null
          ? Timestamp.fromDate(arrivalTime!)
          : null,
      'departureTime': departureTime != null
          ? Timestamp.fromDate(departureTime!)
          : null,
      'vehiclePlateNumber': vehiclePlateNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firebase JSON
  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] ?? '',
      residentId: json['residentId'] ?? '',
      residentName: json['residentName'] ?? '',
      apartmentNumber: json['apartmentNumber'] ?? '',
      visitorName: json['visitorName'] ?? '',
      visitorPhone: json['visitorPhone'] ?? '',
      visitorType: json['visitorType'] ?? 'guest',
      accessCode: json['accessCode'] ?? '',
      validFrom: (json['validFrom'] as Timestamp).toDate(),
      validUntil: (json['validUntil'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      hasArrived: json['hasArrived'] ?? false,
      arrivalTime: json['arrivalTime'] != null
          ? (json['arrivalTime'] as Timestamp).toDate()
          : null,
      departureTime: json['departureTime'] != null
          ? (json['departureTime'] as Timestamp).toDate()
          : null,
      vehiclePlateNumber: json['vehiclePlateNumber'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with modified fields
  VisitorModel copyWith({
    String? id,
    String? residentId,
    String? residentName,
    String? apartmentNumber,
    String? visitorName,
    String? visitorPhone,
    String? visitorType,
    String? accessCode,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    bool? hasArrived,
    DateTime? arrivalTime,
    DateTime? departureTime,
    String? vehiclePlateNumber,
    DateTime? createdAt,
  }) {
    return VisitorModel(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      residentName: residentName ?? this.residentName,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      visitorName: visitorName ?? this.visitorName,
      visitorPhone: visitorPhone ?? this.visitorPhone,
      visitorType: visitorType ?? this.visitorType,
      accessCode: accessCode ?? this.accessCode,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      hasArrived: hasArrived ?? this.hasArrived,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
