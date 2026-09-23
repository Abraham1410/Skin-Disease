import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<dynamic> get(String url,
      {Map<String, String>? headers, Map<String, String>? params}) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('GET failed: ${response.statusCode} - ${response.body}');
    }
  }
}
