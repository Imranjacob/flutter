import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_stat_new_releases');

  const InitializationSettings settings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification taps if needed
    },
  );
}

Future<void> showNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'mychannel',
    'Alert Service',
    channelDescription: 'Background service channel for alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_stat_new_releases',
    ongoing: false,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID based on timestamp
    title,
    body,
    const NotificationDetails(android: androidDetails),
  );
}