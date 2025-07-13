import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  static Future<List<dynamic>> fetchLatestAlerts(String supabaseUrl, String anonKey) async {
    try {
      final url = Uri.parse('$supabaseUrl/rest/v1/alerts?select=*&order=timestamp.desc');
      final response = await http.get(
        url,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Supabase fetch failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Supabase error: $e');
      return [];
    }
  }
}