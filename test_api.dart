import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Added for debugPrint

Future<void> main() async {
  final baseUrl = 'https://equran.id/api/v2/imsakiyah';

  debugPrint('\nTesting POST / with kabkota (lowercase)');
  try {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provinsi': 'Aceh', 'kabkota': 'Kab. Aceh Barat'}),
    );
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
  } catch (e) {
    debugPrint('Error: $e');
  }
}
