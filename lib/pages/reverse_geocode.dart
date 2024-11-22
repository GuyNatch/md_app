// reverse_geocode.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> reverseGeocode(double latitude, double longitude) async {
  final String apiKey = 'cef7f036351b49dfacdaab14049fad29';
  final String url =
      'https://api.opencagedata.com/geocode/v1/json?q=$latitude,$longitude&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        return data['results'][0]['formatted'];
      } else {
        return 'ไม่พบที่อยู่';
      }
    } else {
      return 'ข้อผิดพลาด: ${response.statusCode}';
    }
  } catch (e) {
    return 'ข้อผิดพลาด: $e';
  }
}
