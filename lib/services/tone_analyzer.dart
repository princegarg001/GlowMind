import 'package:flutter/foundation.dart';
import 'package:glowmind/openai/openai_config.dart';

class ToneAnalyzer {
  final OpenAIClient _client;
  ToneAnalyzer(this._client);

  /// Returns a map like: {"sentiment":"negative|neutral|positive","anxiety":0..1,"burnout":0..1}
  Future<Map<String, dynamic>> analyze(String text) async {
    try {
      final system = 'You classify short diary-like text for mental wellness signals. Output JSON with keys: sentiment (negative|neutral|positive), anxiety (0..1), burnout (0..1). No explanations.';
      final json = await _client.chatJson(system: system, user: text);
      return json;
    } catch (e) {
      debugPrint('ToneAnalyzer error: $e');
      // Graceful fallback: simple heuristic
      final t = text.toLowerCase();
      double anx = (t.contains('panic') || t.contains('anxious') || t.contains('overwhelmed')) ? 0.8 : 0.2;
      double bo = (t.contains('tired') || t.contains('burnout') || t.contains('exhausted')) ? 0.7 : 0.2;
      final sentiment = (anx + bo) > 0.9 ? 'negative' : 'neutral';
      return {'sentiment': sentiment, 'anxiety': anx, 'burnout': bo, 'source': 'heuristic'};
    }
  }
}
