import 'dart:convert';
import 'package:http/http.dart' as http;
import 'security_service.dart';

class ImsakiyahService {
  final String baseUrl = 'https://equran.id/api/v2/imsakiyah';
  final http.Client _client = SecurityService.getClient();

  Future<List<String>> getProvinces() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/provinsi'),
      headers: SecurityService.getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
         return List<String>.from(data['data']);
      } else {
        throw Exception('Failed to load provinces: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  Future<List<String>> getCities(String province) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/kabkota'),
      headers: SecurityService.getHeaders(),
      body: json.encode({'provinsi': SecurityService.sanitizeInput(province)}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
       if (data['code'] == 200) {
         return List<String>.from(data['data']);
      } else {
        throw Exception('Failed to load cities: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load cities');
    }
  }

  Future<Map<String, dynamic>> getSchedule(String province, String city) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: SecurityService.getHeaders(),
      body: json.encode({
        'provinsi': SecurityService.sanitizeInput(province), 
        'kabkota': SecurityService.sanitizeInput(city)
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
       if (data['code'] == 200) {
         return data['data'];
      } else {
        throw Exception('Failed to load schedule: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load schedule');
    }
  }
}
