import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps
  Function(String? type, Map<String, dynamic>? data)? onNotificationTap;

  // Timer for repeating notifications
  Timer? _panicNotificationTimer;
  bool _isPanicNotificationActive = false;

  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);

            // Cancel ongoing panic notifications when tapped
            if (data['type'] == 'panic' || data['type'] == 'resident_panic') {
              await stopPanicNotifications();
            }

            onNotificationTap?.call(data['type'], data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'panic_resolved') {
        // Stop panic notifications when alert is resolved
        stopPanicNotifications();
      } else {
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onNotificationTap != null && message.data.isNotEmpty) {
        onNotificationTap!(message.data['type'], message.data);
      }
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Send FCM notification to a specific device token
  Future<bool> sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // For demo purposes - in production, this should be done server-side
      // You'll need to get the server key from Firebase Console
      const serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

      final message = {
        'to': token,
        'notification': {'title': title, 'body': body, 'sound': 'default'},
        'data': data ?? {},
        'priority': 'high',
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending FCM notification: $e');
      return false;
    }
  }

  /// Show local notification for visitor expiry
  Future<void> showVisitorExpiryNotification({
    required String visitorName,
    required String visitorId,
    required DateTime validUntil,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'visitor_expiry_channel',
          'Visitor Expiry Alerts',
          channelDescription: 'Notifications for expiring visitor QR codes',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('default'),
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final data = {
      'type': 'visitor_expiry',
      'visitorId': visitorId,
      'visitorName': visitorName,
      'validUntil': validUntil.toIso8601String(),
    };

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      '🚨 Visitor QR Expiring Soon',
      '${visitorName}\'s access expires in less than 2 hours. Mark as departed or extend validity.',
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'panic_channel',
          'Panic Alerts',
          channelDescription: 'Notifications for panic alerts',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('siren'),
          playSound: true,
          ongoing: false, // Allow dismissal
          autoCancel: true, // Dismiss on tap
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Include data as payload for tap handling
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Alert',
      message.notification?.body ?? 'You have a new alert',
      platformChannelSpecifics,
      payload: payload,
    );

    // Start repeating the notification sound every 3 seconds
    _startPanicNotificationRepeating(message, payload);
  }

  void _startPanicNotificationRepeating(
    RemoteMessage message,
    String? payload,
  ) {
    // Stop any existing panic notification timer
    stopPanicNotifications();

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
            ongoing: false,
            autoCancel: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Use a different ID each time to force the sound to play
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title ?? 'PANIC ALERT!',
        message.notification?.body ??
            'Emergency situation detected. Please stay safe!',
        platformChannelSpecifics,
        payload: payload,
      );
    });
  }

  Future<void> stopPanicNotifications() async {
    _isPanicNotificationActive = false;
    _panicNotificationTimer?.cancel();
    _panicNotificationTimer = null;

    // Cancel specific panic notification IDs
    await _flutterLocalNotificationsPlugin.cancel(
      1,
    ); // Resident panic notification
    await _flutterLocalNotificationsPlugin.cancel(
      2,
    ); // Guard panic notification

    // Cancel any repeating notifications by cancelling recent high IDs
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Cancel notifications from the last 5 minutes that might be repeating
    for (int i = 0; i < 300; i++) {
      await _flutterLocalNotificationsPlugin.cancel(now - i);
      await _flutterLocalNotificationsPlugin.cancel(
        (now - i) + 1000,
      ); // Guard panic offset
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages - show local notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize if not already done
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Show notification based on message type
  if (message.data['type'] == 'panic_resolved') {
    // Stop panic notifications when alert is resolved
    await flutterLocalNotificationsPlugin.cancel(
      1,
    ); // Resident panic notification
    await flutterLocalNotificationsPlugin.cancel(2); // Guard panic notification
    // Cancel any repeating notifications
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int i = 0; i < 300; i++) {
      await flutterLocalNotificationsPlugin.cancel(now - i);
      await flutterLocalNotificationsPlugin.cancel((now - i) + 1000);
    }
  } else if (message.data['type'] == 'visitor_expiry') {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'visitor_expiry_channel',
          'Visitor Expiry Alerts',
          channelDescription: 'Notifications for expiring visitor QR codes',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('default'),
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? '🚨 Visitor QR Expiring Soon',
      message.notification?.body ?? 'A visitor QR code is about to expire',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  } else {
    // Default panic alert style
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'panic_channel',
          'Panic Alerts',
          channelDescription: 'Notifications for panic alerts',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('siren'),
          playSound: true,
          ongoing: false, // Allow dismissal
          onlyAlertOnce: false, // Allow sound to repeat
          autoCancel: true, // Dismiss on tap
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Alert',
      message.notification?.body ?? 'You have a new alert',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
