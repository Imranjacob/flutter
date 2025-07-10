import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

bool _obscureKey = true;

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController urlController = TextEditingController();
  TextEditingController keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    urlController.text = prefs.getString('supabaseUrl') ?? '';
    keyController.text = prefs.getString('anonKey') ?? '';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabaseUrl', urlController.text);
    await prefs.setString('anonKey', keyController.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Settings saved.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("⚙️ Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(labelText: "Supabase URL"),
            ),
            SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: "Supabase anon key",
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureKey = !_obscureKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureKey,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: Icon(Icons.save),
              label: Text("Save Settings"),
            )
          ],
        ),
      ),
    );
  }
}
