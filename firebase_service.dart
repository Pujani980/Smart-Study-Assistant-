import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_study_assistant/models/note_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  // Get or create user stats
  Future<StudyStats> getStudyStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .get();

      if (doc.exists) {
        return StudyStats.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return StudyStats(
          totalNotes: 0,
          totalSummaries: 0,
          totalFlashcards: 0,
          totalStudyTime: 0,
        );
      }
    } catch (e) {
      print('Error fetching study stats: $e');
      return StudyStats(
        totalNotes: 0,
        totalSummaries: 0,
        totalFlashcards: 0,
        totalStudyTime: 0,
      );
    }
  }

  // Get recent notes
  Future<List<Note>> getRecentNotes(String userId, {int limit = 5}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching recent notes: $e');
      return [];
    }
  }

  // Save a note
  Future<void> saveNote(Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(note.userId)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap(), SetOptions(merge: true));

      // Update stats
      await _firestore
          .collection('users')
          .doc(note.userId)
          .collection('stats')
          .doc('overview')
          .update({'totalNotes': FieldValue.increment(1)});
    } catch (e) {
      print('Error saving note: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  // Update summary count
  Future<void> updateSummaryCount(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .update({'totalSummaries': FieldValue.increment(1)});
    } catch (e) {
      print('Error updating summary count: $e');
    }
  }
}
