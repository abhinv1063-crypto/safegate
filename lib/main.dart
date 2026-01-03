import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/guard_home_screen.dart';
import 'screens/guard_scanner_screen.dart';
import 'screens/guard_otp_entry_screen.dart';
import 'screens/guard_surprise_visitor_screen.dart';
import 'screens/guard_current_visitors_screen.dart';
import 'screens/guard_entry_logs_screen.dart';
import 'screens/guard_building_visitors_screen.dart';
import 'screens/guard_panic_alerts_screen.dart';
import 'screens/guard_resident_panic_alerts_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/visitor_service.dart';
import 'services/background_check_service.dart';

void main() async {
  // This ensures Flutter is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - connect to your cloud database
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Set up notification tap handler
  notificationService.onNotificationTap =
      (String? type, Map<String, dynamic>? data) {
        if (type == 'visitor_expiry' && data != null) {
          // Handle visitor expiry notification tap
          // This will be handled by the current screen's context
          print('Visitor expiry notification tapped: ${data['visitorId']}');
        } else if (type == 'panic' || type == 'resident_panic') {
          // Stop repeating panic notifications when tapped
          notificationService.stopPanicNotifications();
        }
      };

  // Store FCM token for current user (if logged in)
  final authService = AuthService();
  try {
    final token = await notificationService.getToken();
    if (token != null && authService.isLoggedIn) {
      await authService.updateFCMToken(token);
    }
  } catch (e) {
    print('Error storing FCM token: $e');
  }

  // Check for expiring visitors on app start
  try {
    final visitorService = VisitorService();
    await visitorService.checkAndNotifyExpiringVisitors();

    // Start background periodic checking
    final backgroundService = BackgroundCheckService();
    backgroundService.startPeriodicCheck();
  } catch (e) {
    print('Error checking expiring visitors on startup: $e');
  }

  // Start the app
  runApp(const SafeGateApp());
}

class SafeGateApp extends StatefulWidget {
  const SafeGateApp({super.key});

  @override
  State<SafeGateApp> createState() => _SafeGateAppState();
}

class _SafeGateAppState extends State<SafeGateApp> with WidgetsBindingObserver {
  final BackgroundCheckService _backgroundService = BackgroundCheckService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundService.stopPeriodicCheck();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground, ensure background checking is running
        if (!_backgroundService.isRunning) {
          _backgroundService.startPeriodicCheck();
        }
        // Also do an immediate check when app resumes
        _backgroundService.checkNow();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background, keep checking running for now
        // In a production app, you might want to pause it to save battery
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App name that appears in phone settings
      title: 'SafeGate',

      // Remove the debug banner in top right
      debugShowCheckedModeBanner: false,

      // Use Material 3 design (modern, clean look)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        // Large text for elderly users
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),

      // Dark mode theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),

      // Start with animated SplashScreen
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => const WelcomeScreen(
          apartmentName: '',
          apartmentNumber: '',
          userData: {},
        ),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/guard_home': (context) => const GuardHomeScreen(),
        '/guard_scanner': (context) => const GuardScannerScreen(),
        '/guard_otp_entry': (context) => const GuardOTPEntryScreen(),
        '/guard_surprise_visitor': (context) =>
            const GuardSurpriseVisitorScreen(),
        '/guard_current_visitors': (context) =>
            const GuardCurrentVisitorsScreen(),
        '/guard_logs': (context) => const GuardEntryLogsScreen(),
        '/guard_building_visitors': (context) =>
            const GuardBuildingVisitorsScreen(),
        '/guard_panic_alerts': (context) => const GuardPanicAlertsScreen(),
        '/guard_resident_panic_alerts': (context) =>
            const GuardResidentPanicAlertsScreen(),
      },
    );
  }
}
