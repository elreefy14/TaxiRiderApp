import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // API endpoint
  String url = 'https://masark-sa.com/api/register';

  // Headers from the app with added User-Agent
  Map<String, String> headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-cache',
    'Accept': 'application/json; charset=utf-8',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
    'User-Agent':
        'MightyTaxiRiderApp', // Custom User-Agent to bypass bot protection
  };

  // Request body
  Map<String, dynamic> body = {
    'first_name': 'Test',
    'last_name': 'User',
    'username':
        'testuser${DateTime.now().millisecondsSinceEpoch}', // Using timestamp to make username unique
    'email':
        'test${DateTime.now().millisecondsSinceEpoch}@example.com', // Using timestamp to make email unique
    'user_type': 'rider',
    'contact_number': '1234567890',
    'country_code': '+1',
    'password': '12345678',
    'player_id': '',
  };

  print('Sending request to: $url');
  print('Headers: $headers');
  print('Body: $body');

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Registration successful');
      final responseJson = jsonDecode(response.body);
      print('Parsed response: $responseJson');
    } else {
      print('Registration failed');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}
