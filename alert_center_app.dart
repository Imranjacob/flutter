import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF1E1E1E),
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFFBB86FC)),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
        ),
      ),
      home: AlertDashboard(),
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
        final dynamic potentialId = event['ID'];
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
    _backgroundSubscription?.cancel();
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
        final latest = alerts.first;
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
          _alerts = alerts;
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

  int? _parseAlertId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Alerts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAlerts,
            tooltip: 'Refresh',
          ),
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
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage()),
              );
            },
            tooltip: 'Chat',
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No alerts detected",
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final msg = alert['message'] ?? '';
          final ts = alert['timestamp'] ?? '';
          final bot = alert['bot_name'] ?? '';

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            color: Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, size: 16, color: Color(0xFFBB86FC)),
                      SizedBox(width: 8),
                      Text(
                        '${bot.isNotEmpty ? bot : 'Alert'}',
                        style: TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        ts.toString(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    msg,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFBB86FC),
        onPressed: () async {
          try {
            await initializeService();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Background service started'),
                backgroundColor: Color(0xFF1E1E1E),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start service: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Icon(Icons.play_arrow, color: Colors.black),
        tooltip: 'Start Service',
      ),
    );
  }
}
