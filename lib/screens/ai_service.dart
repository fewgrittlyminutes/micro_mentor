import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const _apiKey = "API KEY Here";

  static Future<String> generateRoadmap(String topic) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final prompt = "A student wants to learn: '$topic'. Provide a 3-step study roadmap...";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text ?? "Could not generate a roadmap.";
    } catch (e) {
      print("GEMINI ERROR: $e"); 
      return "AI Assistant is currently offline.";
    }
  }
}