import 'dart:async';
import 'package:flutter/material.dart';
import 'visitor_service.dart';

class BackgroundCheckService {
  static final BackgroundCheckService _instance =
      BackgroundCheckService._internal();
  factory BackgroundCheckService() => _instance;
  BackgroundCheckService._internal();

  Timer? _timer;
  bool _isRunning = false;
  final VisitorService _visitorService = VisitorService();

  /// Start periodic checking for expiring visitors
  void startPeriodicCheck() {
    if (_isRunning) return;

    _isRunning = true;
    // Check every 30 minutes (1800000 milliseconds)
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        await _visitorService.checkAndNotifyExpiringVisitors();
      } catch (e) {
        debugPrint('Error in periodic visitor check: $e');
      }
    });

    debugPrint('Background visitor expiry check started');
  }

  /// Stop periodic checking
  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('Background visitor expiry check stopped');
  }

  /// Check immediately (useful when app resumes or user logs in)
  Future<void> checkNow() async {
    try {
      await _visitorService.checkAndNotifyExpiringVisitors();
    } catch (e) {
      debugPrint('Error in immediate visitor check: $e');
    }
  }

  /// Check if service is running
  bool get isRunning => _isRunning;
}
