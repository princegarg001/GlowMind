import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Environment-provided values
const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

class OpenAIClient {
  final http.Client _client;
  OpenAIClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> chatJson({required String system, required String user}) async {
    if (endpoint.isEmpty || apiKey.isEmpty) {
      throw Exception('OpenAI config missing. Set OPENAI_PROXY_ENDPOINT and OPENAI_PROXY_API_KEY.');
    }
    final uri = Uri.parse(endpoint);
    final headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': '$system\nRespond strictly as a JSON object.'},
        {'role': 'user', 'content': user},
      ],
      'temperature': 0.2,
    });
    final res = await _client.post(uri, headers: headers, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content is String) {
        try {
          return jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('OpenAI JSON parse failed: $e');
          return {'error': 'malformed_json', 'raw': content};
        }
      }
      return {'error': 'empty_content'};
    } else {
      debugPrint('OpenAI error ${res.statusCode}: ${res.body}');
      throw Exception('OpenAI request failed: ${res.statusCode}');
    }
  }
}
