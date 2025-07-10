import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchLatestAlerts(String supabaseUrl, String anonKey) async {
  final url = Uri.parse('$supabaseUrl/rest/v1/alerts?select=*');
  final response = await http.get(
    url,
    headers: {
      'apikey': anonKey,
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print('❌ Supabase fetch failed: ${response.statusCode}');
    return [];
  }
}
