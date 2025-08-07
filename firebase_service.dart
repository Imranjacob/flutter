import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications.dart';
import 'supabase_service.dart';
import 'main.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request notification permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission granted: ${settings.authorizationStatus}');

    // Get and store the device token
    await _setupToken();

    // Configure message handlers
    await _configureMessagingHandlers();
  }

  static Future<void> _setupToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Send token to Supabase if needed
      // await SupabaseService.saveDeviceToken(token);
    }
  }

  static Future<void> _configureMessagingHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      _handleMessage(message);
    });

    // When app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background via notification');
      _handleMessage(message, wasTapped: true);
    });
  }

  static void _handleMessage(RemoteMessage message, {bool wasTapped = false}) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      Notifications.showNotification(
        notification.title ?? 'New Alert',
        notification.body ?? '',
      );

      if (wasTapped) {
        // Handle notification tap (e.g., navigate to specific screen)
        // You might want to use a global navigator key for this
      }
    }

    // Handle Supabase alert data if sent via FCM
    if (data.isNotEmpty && data.containsKey('alert_id')) {
      print('Received alert data: $data');
      // You might want to refresh alerts when receiving new data
    }
  }
}