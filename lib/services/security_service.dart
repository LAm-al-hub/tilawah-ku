import 'package:http/http.dart' as http;

class SecurityService {
  static const String _userAgent = 'TilawahKU/1.0.0'; // Custom User-Agent

  static Map<String, String> getHeaders() {
    return {
      'User-Agent': _userAgent,
      'Content-Type': 'application/json',
      // Add other security headers here if the API supports them (e.g., specific API keys)
    };
  }

  static http.Client getClient() {
    // In a real secure app, we might implement certificate pinning here
    // using packages like http_certificate_pinning or native implementation.
    // For now, we return a standard client but this is the place to hook it in.
    return http.Client();
  }
  
  static String sanitizeInput(String input) {
    // Basic sanitization to prevent injection if input is used in specific contexts
    // Note: Flutter/Dart standard libraries handle most JSON encoding safety.
    return input.replaceAll(RegExp(r'[<>]'), '');
  }
}
