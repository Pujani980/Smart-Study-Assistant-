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
      // Fetch real collection data so counts and study time are always accurate.
      final notesSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      final flashcardsSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .get();

      // Read totalSummaries from the stats doc (this counter IS maintained).
      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .get();
      final totalSummaries = statsDoc.exists
          ? (statsDoc.data()?['totalSummaries'] as int?) ?? 0
          : 0;

      // Compute study time from real activity:
      //   • 1 minute per flashcard review
      //   • 5 minutes per note created
      int totalCardReviews = 0;
      for (final doc in flashcardsSnap.docs) {
        totalCardReviews += (doc.data()['timesReviewed'] as int? ?? 0);
      }
      final totalStudyTime = totalCardReviews + (notesSnap.docs.length * 5);

      return StudyStats(
        totalNotes: notesSnap.docs.length,
        totalSummaries: totalSummaries,
        totalFlashcards: flashcardsSnap.docs.length,
        totalStudyTime: totalStudyTime,
      );
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

  // Delete multiple notes
  Future<void> bulkDeleteNotes(String userId, List<String> noteIds) async {
    try {
      final batch = _firestore.batch();

      for (final noteId in noteIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(noteId);
        batch.delete(docRef);
      }

      await batch.commit();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .set({
            'totalNotes': FieldValue.increment(-noteIds.length),
            'updatedAt': DateTime.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error bulk deleting notes: $e');
      rethrow;
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

  // Save a flashcard
  Future<void> saveFlashcard(Flashcard flashcard) async {
    try {
      await _firestore
          .collection('users')
          .doc(flashcard.userId)
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toMap(), SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(flashcard.userId)
          .collection('stats')
          .doc('overview')
          .set({
            'totalFlashcards': FieldValue.increment(1),
            'updatedAt': DateTime.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving flashcard: $e');
      rethrow;
    }
  }

  // Update an existing flashcard
  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      final updatedFlashcard = flashcard.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('users')
          .doc(flashcard.userId)
          .collection('flashcards')
          .doc(flashcard.id)
          .update(updatedFlashcard.toMap());
    } catch (e) {
      print('Error updating flashcard: $e');
      rethrow;
    }
  }

  // Delete a flashcard
  Future<void> deleteFlashcard(String userId, String flashcardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(flashcardId)
          .delete();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .set({
            'totalFlashcards': FieldValue.increment(-1),
            'updatedAt': DateTime.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error deleting flashcard: $e');
      rethrow;
    }
  }
}
