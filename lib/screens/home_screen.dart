import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../services/auth_service.dart';
import 'create_invitation_screen.dart';
import 'create_delivery_otp_screen.dart';
import 'change_password_screen.dart';
import 'frequent_visitors_screen.dart';
import 'visitor_history_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../utils/date_time_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Map<String, dynamic>? residentData;
  bool isLoading = true;
  Set<String> _notifiedAlertIds = {}; // Track already notified alerts
  Set<String> _resolvedAlertIds = {}; // Track already resolved alerts
  Set<String> _visitorRequestIds =
      {}; // Track already notified visitor requests
  Timer? _panicNotificationTimer;
  bool _isPanicNotificationActive = false;

  @override
  void initState() {
    super.initState();
    _loadResidentData();
  }

  // Load resident information
  Future<void> _loadResidentData() async {
    final data = await _authService.getResidentData();
    setState(() {
      residentData = data;
      isLoading = false;
    });
    await _setupNotifications();
    _listenForPanicAlerts();
  }

  Future<void> _setupNotifications() async {
    if (residentData != null && residentData!['apartmentName'] != null) {
      String apartmentId = residentData!['apartmentName']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      await _notificationService.subscribeToTopic('residents_$apartmentId');
    }
    _notificationService.onNotificationTap = _onNotificationTap;
  }

  void _listenForPanicAlerts() {
    if (residentData == null || residentData!['apartmentName'] == null) return;

    String apartmentId = residentData!['apartmentName']
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartmentId)
        .collection('panic_alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final alertId = doc.id;
            if (!_notifiedAlertIds.contains(alertId)) {
              _notifiedAlertIds.add(alertId);
              final alert = doc.data();
              if (alert != null) {
                alert['id'] = alertId;
                _showPanicNotification(alert);
              }
            }
          }
        });

    // Listen for resolved alerts to stop notifications
    FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartmentId)
        .collection('panic_alerts')
        .where('status', isEqualTo: 'resolved')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final alertId = doc.id;
            if (!_resolvedAlertIds.contains(alertId)) {
              _resolvedAlertIds.add(alertId);
              _notificationService.stopPanicNotifications();
            }
          }
        });

    // Listen for visitor requests
    FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartmentId)
        .collection('visitor_requests')
        .where('residentId', isEqualTo: _authService.currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final requestId = doc.id;
            if (!_visitorRequestIds.contains(requestId)) {
              _visitorRequestIds.add(requestId);
              final request = doc.data() as Map<String, dynamic>;
              _showVisitorRequestNotification(request);
            }
          }
        });
  }

  Future<void> _showPanicNotification(Map<String, dynamic> alert) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'panic_channel',
          'Panic Alerts',
          channelDescription: 'Notifications for panic alerts',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('siren'),
          playSound: true,
          ongoing: true, // Make notification persistent
          autoCancel: false, // Don't auto-cancel when tapped
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final payload = jsonEncode({'type': 'panic', 'alertId': alert['id'] ?? ''});

    await _flutterLocalNotificationsPlugin.show(
      0,
      'PANIC ALERT!',
      'Emergency situation detected. Please stay safe and follow security instructions.',
      platformChannelSpecifics,
      payload: payload,
    );

    // Start repeating the notification sound every 3 seconds
    _startPanicNotificationRepeating(payload);
  }

  Future<void> _showVisitorRequestNotification(
    Map<String, dynamic> request,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'visitor_channel',
          'Visitor Requests',
          channelDescription: 'Notifications for visitor approval requests',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('default'),
          playSound: true,
          ongoing: false,
          autoCancel: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final payload = jsonEncode({
      'type': 'visitor_request',
      'requestId': request['id'],
      'visitorName': request['visitorName'],
    });

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Visitor Request',
      '${request['visitorName']} is requesting to visit. Please approve or reject.',
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _onNotificationTap(String? type, Map<String, dynamic>? data) {
    if (type == 'visitor_request') {
      // Navigate to notifications screen
      Navigator.pushNamed(context, '/notifications');
    } else if (type == 'panic') {
      // Stop panic notifications
      _notificationService.stopPanicNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('SafeGate'),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // Notifications button
          IconButton(
            icon: const Icon(Icons.notifications, size: 28),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : residentData == null
          ? const Center(child: Text('Error loading data'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Text(
                                  residentData!['residentName'][0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome Back!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      residentData!['residentName'],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displayMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      residentData!['apartmentName'] ??
                                          'Unknown Apartment',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Apartment ${residentData!['apartmentNumber']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Active Guard Emergency Alerts Section
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        residentData != null &&
                            residentData!['apartmentName'] != null
                        ? FirebaseFirestore.instance
                              .collection('apartments')
                              .doc(
                                residentData!['apartmentName']
                                    .toString()
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'[^a-z0-9]'), ''),
                              )
                              .collection('panic_alerts')
                              .where('status', isEqualTo: 'active')
                              .orderBy('timestamp', descending: true)
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final alerts = snapshot.data!.docs;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚨 Active Guard Emergency Alerts',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...alerts.map((doc) {
                            final alert = doc.data() as Map<String, dynamic>;
                            return Card(
                              elevation: 4,
                              color: Colors.red[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.red[700],
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'GUARD EMERGENCY ALERT',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'From: ${alert['guardName']} (Security Guard)',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[800],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Time: ${DateTimeFormatter.formatDateTime((alert['timestamp'] as Timestamp?)!.toDate())}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _acknowledgeGuardAlert(doc.id),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Acknowledge'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Your Emergency Alerts Section
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        residentData != null &&
                            residentData!['apartmentName'] != null
                        ? FirebaseFirestore.instance
                              .collection('apartments')
                              .doc(
                                residentData!['apartmentName']
                                    .toString()
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'[^a-z0-9]'), ''),
                              )
                              .collection('resident_panic_alerts')
                              .where('status', isEqualTo: 'active')
                              .orderBy('timestamp', descending: true)
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final alerts = snapshot.data!.docs;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Emergency Alerts',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...alerts.map((doc) {
                            final alert = doc.data() as Map<String, dynamic>;
                            return Card(
                              elevation: 4,
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.emergency,
                                          color: Colors.orange[700],
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'EMERGENCY ALERT',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Triggered by you',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[800],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Time: ${DateTimeFormatter.formatDateTime((alert['timestamp'] as Timestamp?)!.toDate())}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      alert['message'] ??
                                          'Emergency alert triggered',
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.4,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _cancelResidentAlert(doc.id),
                                          icon: const Icon(Icons.cancel),
                                          label: const Text('Cancel Alert'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),

                  // Section Title
                  Text(
                    'Visitor Management',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),

                  const SizedBox(height: 16),

                  // Invite Visitor Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.qr_code,
                    title: 'Invite Visitor',
                    subtitle: 'Generate QR code for family & friends',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateInvitationScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Delivery OTP Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.local_shipping,
                    title: 'Delivery OTP',
                    subtitle: 'One-time code for deliveries',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateDeliveryOTPScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Frequent Visitors Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.person_add,
                    title: 'Frequent Visitors',
                    subtitle: 'Manage regular visitors (maid, etc.)',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FrequentVisitorsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Visitor History Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.history,
                    title: 'Visitor History',
                    subtitle: 'View past visitor entries',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VisitorHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Settings Section
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),

                  const SizedBox(height: 16),

                  // Change Password Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.key,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),

                  // Emergency Section
                  Text(
                    'Emergency',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),

                  const SizedBox(height: 16),

                  // Alert Security Button
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.warning,
                    title: 'Alert Security',
                    subtitle: 'Send emergency notification',
                    color: Colors.red,
                    onTap: _showPanicConfirmation,
                  ),
                ],
              ),
            ),
    );
  }

  // Build feature card widget
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacementNamed('/'); // Go to login
              }
            },
            child: Text(
              'LOGOUT',
              style: TextStyle(fontSize: 16, color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanicConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 32),
            const SizedBox(width: 10),
            const Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'Are you sure you want to send an emergency alert to security?\n\nThis should only be used in genuine emergency situations.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerResidentPanic();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerResidentPanic() async {
    try {
      // Get apartment ID
      String apartmentId = residentData!['apartmentName']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Create resident panic alert in global collection
      await FirebaseFirestore.instance.collection('resident_panic_alerts').add({
        'residentId': residentData!['uid'],
        'residentName': residentData!['residentName'],
        'apartmentNumber': residentData!['apartmentNumber'],
        'apartmentName': residentData!['apartmentName'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active', // active, resolved
      });

      // Also create in apartment-specific collection for guards
      await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .collection('resident_panic_alerts')
          .add({
            'residentId': residentData!['uid'],
            'residentName': residentData!['residentName'],
            'apartmentNumber': residentData!['apartmentNumber'],
            'apartmentName': residentData!['apartmentName'],
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'active', // active, resolved
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to security!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acknowledgeGuardAlert(String alertId) async {
    try {
      String apartmentId = residentData!['apartmentName']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .collection('panic_alerts')
          .doc(alertId)
          .update({'status': 'acknowledged'});

      // Remove from notified alerts set
      _notifiedAlertIds.remove(alertId);

      // Stop panic notifications
      await _notificationService.stopPanicNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startPanicNotificationRepeating(String? payload) {
    // Stop any existing panic notification timer
    _stopPanicNotifications();

    _isPanicNotificationActive = true;

    // Create repeating notification that plays sound every 3 seconds
    _panicNotificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      if (!_isPanicNotificationActive) {
        timer.cancel();
        return;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'panic_channel',
            'Panic Alerts',
            channelDescription: 'Notifications for panic alerts',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('siren'),
            playSound: true,
            ongoing: true,
            autoCancel: false,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Use a different ID each time to force the sound to play
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _flutterLocalNotificationsPlugin.show(
        notificationId,
        'PANIC ALERT!',
        'Emergency situation detected. Please stay safe and follow security instructions.',
        platformChannelSpecifics,
        payload: payload,
      );
    });
  }

  void _stopPanicNotifications() {
    _isPanicNotificationActive = false;
    _panicNotificationTimer?.cancel();
    _panicNotificationTimer = null;

    // Cancel all panic-related notifications
    _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _cancelResidentAlert(String alertId) async {
    try {
      String apartmentId = residentData!['apartmentName']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .collection('resident_panic_alerts')
          .doc(alertId)
          .update({'status': 'cancelled'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert cancelled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
