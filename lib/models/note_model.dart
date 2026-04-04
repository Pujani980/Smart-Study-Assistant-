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
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      category: map['category'] as String? ?? 'General',
      userId: map['userId'] as String? ?? '',
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
