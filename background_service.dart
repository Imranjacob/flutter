import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeService() async {
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_stat_new_releases');

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
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
  final supabaseUrl = prefs.getString('supabaseUrl') ?? '';
  final anonKey = prefs.getString('anonKey') ?? '';

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  // Initial notification
  flutterLocalNotificationsPlugin.show(
    1234,
    'Alert Service Running',
    'Monitoring started at ${DateTime.now()}',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'mychannel',
        'Alert Service',
        channelDescription: 'Background service channel for alerts',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        icon: '@mipmap/ic_stat_new_releases',
      ),
    ),
  );

  // Periodic check for alerts
  Timer.periodic(const Duration(minutes: 3), (timer) async {
    if (service is AndroidServiceInstance && !(await service.isForegroundService())) {
      return;
    }

    try {
      final alerts = await fetchLatestAlerts(supabaseUrl, anonKey);
      if (alerts.isNotEmpty) {
        final lastAlert = alerts.last;
        flutterLocalNotificationsPlugin.show(
          1235, // Different ID for alert notifications
          'New Alert: ${lastAlert['bot_name'] ?? 'Unknown'}',
          lastAlert['message'] ?? 'No message',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'mychannel',
              'Alert Service',
              channelDescription: 'Background service channel for alerts',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_stat_new_releases',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    }

    // Update service status
    flutterLocalNotificationsPlugin.show(
      1234,
      'Alert Service Running',
      'Last checked at ${DateTime.now()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mychannel',
          'Alert Service',
          channelDescription: 'Background service channel for alerts',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          icon: '@mipmap/ic_stat_new_releases',
        ),
      ),
    );
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}