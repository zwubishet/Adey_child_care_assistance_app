import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  Gemini.init(apiKey: 'AIzaSyCZd4CRpV_LRLKsCfNSE2DI3DgEA4_xj2c');
  try {
    final response = await Gemini.instance.text('Translate "Hello" to Amharic');
    print('Full response: $response');
    print('Content: ${response?.content}');
    print('Parts: ${response?.content?.parts}');
    if (response?.content?.parts?.isNotEmpty == true) {
      final part = response!.content!.parts![0];
      print('First part: $part');
      print('First part toString: ${part.toString()}');
      print('Part runtime type: ${part.runtimeType}');
      // Check if part is a map or has other properties
      if (part is Map) {
        print('Part as Map: $part');
      }
      // Try accessing raw response data
      print('Content role: ${response.content?.role}');
      print('Response finish reason: ${response.finishReason}');
    }
    // Inspect Candidates properties
    print('Candidates output: ${response?.output}');
  } catch (e) {
    print('Error: $e');
  }
}
