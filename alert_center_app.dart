import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_service.dart' as BackgroundService;
import 'notifications.dart';
import 'supabase_service.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'background_service.dart';

class AlertCenterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alert Center',
      theme: ThemeData.dark(),
      home: AlertDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AlertDashboard extends StatefulWidget {
  @override
  _AlertDashboardState createState() => _AlertDashboardState();
}

class _AlertDashboardState extends State<AlertDashboard> {
  List<dynamic> _alerts = [];
  String supabaseUrl = '';
  String anonKey = '';
  bool connected = false;
  bool _isLoading = false;
  int? _lastAlertId;
  Timer? _refreshTimer;

  StreamSubscription? _backgroundSubscription;


  @override
  void initState() {
    super.initState();
    _showNotification;
    _loadSettings().then((_) {
      if (mounted) {
        fetchAlerts().then((_) {
          if (mounted) {
            _startAutoRefresh();
            _setupBackgroundListener();

          }
        });
      }
    });
  }


  void _setupBackgroundListener() {
    FlutterBackgroundService().on('new_alert').listen((event) {
      if (event != null && mounted) {
        final dynamic potentialId = event['id'];
        final int? currentId = potentialId is int ? potentialId : null;

        if (currentId != null) {
          setState(() {
            _alerts = [event, ..._alerts];
            _lastAlertId = currentId;
          });
        }
      }
    });
  }



  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) {
      fetchAlerts();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      supabaseUrl = prefs.getString('supabaseUrl') ?? '';
      anonKey = prefs.getString('anonKey') ?? '';
    });
  }



  Future<void> fetchAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await SupabaseService.fetchLatestAlerts(supabaseUrl, anonKey);
      if (alerts.isNotEmpty) {
        final latest = alerts.last;
        final currentId = _parseAlertId(latest['ID']);

        if (currentId != null && (_lastAlertId == null || currentId != _lastAlertId)) {
          _lastAlertId = currentId;
          await Notifications.showNotification(
              "🔔 New Alert",
              latest['message']?.toString() ?? ''
          );
        }
      }

      if (mounted) {
        setState(() {
          _alerts = alerts.reversed.toList();
          connected = alerts.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => connected = false);
      }
      debugPrint('Error fetching alerts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showNotification({required String title, required String body, required int id}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'mychannel',
      'Alert Service',
      channelDescription: 'Important alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id, // Unique ID for each notification
      title,
      body,
      platformChannelSpecifics,
    );
  }


  int? _parseAlertId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('📡 Supabase Alerts'),
            Text(
              connected ? "🟢 Connected" : "🔴 Disconnected",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchAlerts),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
              await _loadSettings();
              await fetchAlerts();
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage()),
              );
            },
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? Center(child: Text("No alerts detected. Chill."))
          : ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final msg = alert['message'] ?? '';
          final ts = alert['timestamp'] ?? '';
          final bot = alert['bot_name'] ?? '';
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade200.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Timestamp: $ts', style: TextStyle(fontSize: 15)),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Message: $msg', style: TextStyle(fontSize: 15)),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Bot Name: $bot', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await BackgroundService.initializeService();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Background service started')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start service: $e')),
            );
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Service'),
      ),
    );
  }
}