import 'package:cloud_firestore/cloud_firestore.dart';

/// Flashcard Model - Member 4 Implementation
/// Represents a single flashcard with question-answer pair
/// Properties include difficulty, review count, and marked status

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String noteId;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int difficulty; // 1-5 difficulty level
  final int timesReviewed; // Number of times the card was reviewed
  final bool isMarked; // For marking important cards

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.noteId,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.difficulty = 3,
    this.timesReviewed = 0,
    this.isMarked = false,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'noteId': noteId,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'difficulty': difficulty,
      'timesReviewed': timesReviewed,
      'isMarked': isMarked,
    };
  }

  /// Create Flashcard from Firestore document
  factory Flashcard.fromMap(Map<String, dynamic> map, String docId) {
    return Flashcard(
      id: docId,
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      noteId: map['noteId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      difficulty: map['difficulty'] as int? ?? 3,
      timesReviewed: map['timesReviewed'] as int? ?? 0,
      isMarked: map['isMarked'] as bool? ?? false,
    );
  }

  /// Create a copy of this flashcard with optional parameter changes
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? noteId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? difficulty,
    int? timesReviewed,
    bool? isMarked,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      difficulty: difficulty ?? this.difficulty,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      isMarked: isMarked ?? this.isMarked,
    );
  }
}
