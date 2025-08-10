import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']??''; // Replace with your actual API key
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
    
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-pro-vision-latest',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
  }

  Future<String> sendMessage(String message, {List<Content>? history}) async {
    try {
      late final ChatSession chat;
      
      if (history != null && history.isNotEmpty) {
        chat = _model.startChat(history: history);
      } else {
        chat = _model.startChat();
      }
      
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      print('Error sending message to Gemini: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  Future<String> sendImageMessage(
    String prompt, 
    Uint8List imageBytes, {
    List<Content>? history
  }) async {
    try {
      late final ChatSession chat;
      
      if (history != null && history.isNotEmpty) {
        chat = _visionModel.startChat(history: history);
      } else {
        chat = _visionModel.startChat();
      }
      
      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);
      
      final response = await chat.sendMessage(content);
      return response.text ?? 'Sorry, I couldn\'t analyze the image.';
    } catch (e) {
      print('Error sending image to Gemini: $e');
      return 'Sorry, I encountered an error analyzing the image.';
    }
  }
}
