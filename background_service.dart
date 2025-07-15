import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'alert_center_app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeService() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  // Create notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mychannel',
    'Alert Service',
    description: 'Background service channel for alerts',
    importance: Importance.high,
    playSound: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configure the service
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'mychannel',
      initialNotificationTitle: 'Alert Service',
      initialNotificationContent: 'Monitoring is active...',
      foregroundServiceNotificationId: 1234,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize last alert tracking
  int? lastAlertId = prefs.getInt('lastAlertId');

  bool isFirstRun = true;

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  // Show persistent notification
  flutterLocalNotificationsPlugin.show(
    1234,
    'Alert Service',
    'Monitoring for new alerts...',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'mychannel',
        'Alert Service',
        channelDescription: 'Background service channel for alerts',
        importance: Importance.high,
        priority: Priority.low,
        ongoing: true,
        icon: '@mipmap/ic_launcher',
        showWhen: false,
      ),
    ),
  );

  // Periodic check for new alerts
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    try {
      final supabaseUrl = prefs.getString('supabaseUrl') ?? '';
      final anonKey = prefs.getString('anonKey') ?? '';

      if (supabaseUrl.isEmpty || anonKey.isEmpty) return;

      final alerts = await SupabaseService.fetchLatestAlerts(supabaseUrl, anonKey);

      if (alerts.isNotEmpty) {
        final latest = alerts.first;

        // DEBUG: Print latest alert structure
        print("Latest alert: ${latest.toString()}");

        // SAFELY extract ID (replace 'id' if it's really 'alert_id' or 'uuid')
        final dynamic rawId = latest['ID'];
        final int? currentId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

        if (currentId == null) {
          print('⚠️ Background fetch skipped: null or invalid alert ID');
          return;
        }

        // Skip notification on first run (just store the ID)
        if (isFirstRun) {
          await prefs.setInt('lastAlertId', currentId);
          isFirstRun = false;
          print("🔹 First run: Stored ID $currentId");
          return;
        }

        // Only notify if it's a new alert
        if (lastAlertId == null || currentId != lastAlertId) {
          lastAlertId = currentId;
          await prefs.setInt('lastAlertId', currentId);

          await flutterLocalNotificationsPlugin.show(
            currentId.hashCode,
            'New Alert: ${latest['title'] ?? 'Alert'}',
            latest['message'] ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'mychannel',
                'Alert Service',
                channelDescription: 'New alert notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );

          service.invoke('new_alert', latest);
        }
      }
    } catch (e, st) {
      print('❌ Background fetch error: $e');
      print('🔍 Stack trace: $st');
    }
  });
}
