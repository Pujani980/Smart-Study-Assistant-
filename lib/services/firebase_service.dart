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

  // ==================================================
  // MEMBER 3: NOTES LIBRARY MANAGER - New Methods
  // ==================================================

  /// Get all notes for a user
  /// Returns all notes ordered by creation date (most recent first)
  Future<List<Note>> getAllNotes(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching all notes: $e');
      return [];
    }
  }

  /// Get notes filtered by category
  /// Useful for category-based filtering in the notes library
  Future<List<Note>> getNotesByCategory(String userId, String category) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching notes by category: $e');
      return [];
    }
  }

  /// Get notes within a date range
  /// Filters notes created between startDate and endDate
  Future<List<Note>> getNotesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching notes by date range: $e');
      return [];
    }
  }

  /// Search notes by title or content
  /// Performs client-side search on all notes (for better UX)
  Future<List<Note>> searchNotes(String userId, String query) async {
    try {
      final allNotes = await getAllNotes(userId);

      if (query.isEmpty) {
        return allNotes;
      }

      final lowerQuery = query.toLowerCase();
      return allNotes
          .where(
            (note) =>
                note.title.toLowerCase().contains(lowerQuery) ||
                note.content.toLowerCase().contains(lowerQuery) ||
                note.summary.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  /// Update an existing note
  /// Preserves the creation date and only updates the updatedAt field
  Future<void> updateNote(Note note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('users')
          .doc(note.userId)
          .collection('notes')
          .doc(note.id)
          .update(updatedNote.toMap());

      print('Note updated successfully');
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  /// Delete multiple notes in batch
  /// Efficiently deletes multiple notes from Firestore
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

      // Update stats - decrement total notes
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .update({'totalNotes': FieldValue.increment(-noteIds.length)});

      print('${noteIds.length} notes deleted successfully');
    } catch (e) {
      print('Error bulk deleting notes: $e');
      rethrow;
    }
  }

  /// Get note count by category
  /// Useful for displaying category statistics
  Future<Map<String, int>> getNoteCountByCategory(String userId) async {
    try {
      final allNotes = await getAllNotes(userId);
      final categoryCount = <String, int>{};

      for (final note in allNotes) {
        categoryCount[note.category] = (categoryCount[note.category] ?? 0) + 1;
      }

      return categoryCount;
    } catch (e) {
      print('Error getting note count by category: $e');
      return {};
    }
  }

  /// Get notes count for the user
  /// Useful for quick statistics
  Future<int> getNoteCount(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('Error getting note count: $e');
      return 0;
    }
  }

  /// Delete a note by ID (single delete - use bulkDeleteNotes for multiple)
  /// Now updated to also decrement the note count in stats
  Future<void> deleteNoteWithStatUpdate(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();

      // Update stats
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .update({'totalNotes': FieldValue.increment(-1)});
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }
}
