import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';
import 'security_service.dart';

class QuranApiService {
  static const String _baseUrl = 'https://equran.id/api';
  final http.Client _client = SecurityService.getClient();

  Future<List<Surah>> getSurahList() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/surat'),
        headers: SecurityService.getHeaders(),
      );
      debugPrint("API List Response: ${response.statusCode}");
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          data = decoded['data'];
        } else {
           debugPrint("Unexpected API format: $decoded");
        }

        return data.map((json) => Surah.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load Surah list');
      }
    } catch (e) {
       debugPrint("Error fetching surah list: $e");
       throw Exception('Error fetching Surah list: $e');
    }
  }

  Future<Map<String, dynamic>> getSurahDetail(int number) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/surat/$number'),
        headers: SecurityService.getHeaders(),
      );
      debugPrint("API Detail Response ($number): ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        Map<String, dynamic> data;
        if (body.containsKey('data')) {
            data = body['data'];
        } else {
            // Fallback: assume the body itself is the data
            data = body;
        }

        // Extract ayahs
        final List<dynamic> ayahsJson = data['ayat'];
        final List<Ayah> ayahs = ayahsJson.map((json) => Ayah.fromJson(json, number)).toList();
        
        return {
          'surah': Surah.fromJson(data),
          'ayahs': ayahs,
        };
      } else {
        throw Exception('Failed to load Surah detail: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Detailed Error: $e");
      throw Exception('Error fetching Surah detail: $e');
    }
  }
}
