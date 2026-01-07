// lib/models/question.dart
class Question {
  final String? id;
  final String text;
  final List<String> options;
  final int correctIndex; // -1 if no correct answer (e.g., input collection)
  final String answer;

  const Question({
    this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.answer,
  });
}
