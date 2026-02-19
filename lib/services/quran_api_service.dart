import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranApiService {
  static const String _baseUrl = 'https://equran.id/api';

  Future<List<Surah>> getSurahList() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/surat'));
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
      final response = await http.get(Uri.parse('$_baseUrl/surat/$number'));
      debugPrint("API Detail Response ($number): ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        // Based on the log, the API returns the data directly in the root for detail call, OR 'data' is null but the fields are there?
        // Let's check the log carefully.
        // Log says: API Response (1): {"nomor":1,"nama":"الفاتحة", ... "ayat":[...]}
        // It seems the structure is DIRECTLY the object, NOT wrapped in 'data' field for single surah detail?
        // Wait, the log shows: API Response (1): {"nomor":1...}
        // BUT the previous code was: final Map<String, dynamic> data = body['data'];
        // And it threw "Data is null".
        // This confirms that for /surat/{number}, the response IS the data object itself, not wrapped in "data".
        
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
