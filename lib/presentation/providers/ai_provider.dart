//ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIProvider extends StateNotifier<String> {
  AIProvider() : super('');

  void setAI(String ai) {
    state = ai;
  }
}
