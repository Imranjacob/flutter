import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Alert Service',
      initialNotificationContent: 'Monitoring active',
    ),
    iosConfiguration: IosConfiguration(), // empty to satisfy required param, but it's ignored
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized(); // only needed for isolate startup

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  service.on('setAsBackground').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setAsBackgroundService();
    }
  });

  service.on('setAsForeground').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Run background task every 30s
  while (service is AndroidServiceInstance && await service.isForegroundService()) {
    final now = DateTime.now().toIso8601String();
    print('[SERVICE] Ping at $now');

    // Do your background logic here
    // Example: call API, check metrics, etc.

    await Future.delayed(Duration(seconds: 30));
  }
}
