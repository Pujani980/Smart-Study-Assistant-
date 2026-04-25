import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String summary;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String category;
  final String userId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.createdAt,
    this.updatedAt,
    required this.category,
    required this.userId,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'category': category,
      'userId': userId,
    };
  }

  // Create Note from Firestore document
  factory Note.fromMap(Map<String, dynamic> map, String docId) {
    return Note(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      summary: map['summary'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      category: map['category'] ?? 'General',
      userId: map['userId'] ?? '',
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? userId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      userId: userId ?? this.userId,
    );
  }
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String noteId;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int difficulty;
  final int timesReviewed;
  final bool isMarked;

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

  static int _parseDifficulty(dynamic value) {
    if (value is int) {
      return value.clamp(1, 5);
    }

    if (value is num) {
      return value.round().clamp(1, 5);
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      const difficultyLabels = {
        'easy': 1,
        'medium': 3,
        'hard': 5,
        'very easy': 1,
        'very hard': 5,
      };

      if (difficultyLabels.containsKey(normalized)) {
        return difficultyLabels[normalized]!;
      }

      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return parsed.clamp(1, 5);
      }
    }

    return 3;
  }

  static int _parseReviewCount(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

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
      difficulty: _parseDifficulty(map['difficulty']),
      timesReviewed: _parseReviewCount(map['timesReviewed']),
      isMarked: map['isMarked'] as bool? ?? false,
    );
  }

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

class StudyStats {
  final int totalNotes;
  final int totalSummaries;
  final int totalFlashcards;
  final int totalStudyTime; // in minutes

  StudyStats({
    required this.totalNotes,
    required this.totalSummaries,
    required this.totalFlashcards,
    required this.totalStudyTime,
  });

  factory StudyStats.fromMap(Map<String, dynamic> map) {
    return StudyStats(
      totalNotes: map['totalNotes'] ?? 0,
      totalSummaries: map['totalSummaries'] ?? 0,
      totalFlashcards: map['totalFlashcards'] ?? 0,
      totalStudyTime: map['totalStudyTime'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalNotes': totalNotes,
      'totalSummaries': totalSummaries,
      'totalFlashcards': totalFlashcards,
      'totalStudyTime': totalStudyTime,
    };
  }
}
