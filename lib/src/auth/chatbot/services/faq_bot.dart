// lib/services/faq_bot.dart
import '../data/questions.dart';
import '../models/question.dart';

class FaqBot {
  /// Returns a Question if it exists by id; otherwise null.
  Question? getById(String id) {
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Optional: find by text (exact match only to enforce “particular question only”).
  Question? getByExactText(String text) {
    try {
      return questions.firstWhere((q) => q.text.trim() == text.trim());
    } catch (_) {
      return null;
    }
  }
}
