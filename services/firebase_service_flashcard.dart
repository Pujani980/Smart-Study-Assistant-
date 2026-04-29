import 'package:cloud_firestore/cloud_firestore.dart';
import 'flashcard_model.dart';

/// Firebase Service - Flashcard Methods Only
/// Member 4 Implementation
/// Contains all Firestore operations for flashcards

class FlashcardFirebaseService {
  static final FlashcardFirebaseService _instance =
      FlashcardFirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FlashcardFirebaseService._internal();

  factory FlashcardFirebaseService() {
    return _instance;
  }

  // ==================================================
  // FLASHCARD CRUD OPERATIONS
  // ==================================================

  /// Save a new flashcard or update existing one
  /// Creates a Flashcard document in Firestore
  /// Updates flashcard count in user stats
  Future<void> saveFlashcard(Flashcard flashcard) async {
    try {
      await _firestore
          .collection('users')
          .doc(flashcard.userId)
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toMap(), SetOptions(merge: true));

      // Check if this is a new flashcard (not an update)
      // We'll check if it was recently created
      final now = DateTime.now();
      final createdRecently = now.difference(flashcard.createdAt).inMinutes < 1;

      if (createdRecently) {
        // Update or create flashcard count in stats using set with merge
        await _firestore
            .collection('users')
            .doc(flashcard.userId)
            .collection('stats')
            .doc('overview')
            .set({
              'totalFlashcards': FieldValue.increment(1),
              'updatedAt': DateTime.now(),
            }, SetOptions(merge: true));
      }

      print('Flashcard saved successfully');
    } catch (e) {
      print('Error saving flashcard: $e');
      rethrow;
    }
  }

  /// Get all flashcards for a user
  /// Returns all flashcards ordered by creation date (most recent first)
  Future<List<Flashcard>> getAllFlashcards(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching all flashcards: $e');
      return [];
    }
  }

  /// Get flashcards for a specific note/set
  /// Useful for practicing flashcards from a specific note
  Future<List<Flashcard>> getFlashcardsByNote(
    String userId,
    String noteId,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('noteId', isEqualTo: noteId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching flashcards by note: $e');
      return [];
    }
  }

  /// Get marked/important flashcards
  /// Useful for focusing on difficult cards
  Future<List<Flashcard>> getMarkedFlashcards(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('isMarked', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching marked flashcards: $e');
      return [];
    }
  }

  /// Get flashcards by difficulty level
  /// Useful for difficulty-based filtering
  Future<List<Flashcard>> getFlashcardsByDifficulty(
    String userId,
    int difficulty,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('difficulty', isEqualTo: difficulty)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching flashcards by difficulty: $e');
      return [];
    }
  }

  /// Update an existing flashcard
  /// Updates the flashcard document and sets updatedAt
  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      final updatedFlashcard = flashcard.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('users')
          .doc(flashcard.userId)
          .collection('flashcards')
          .doc(flashcard.id)
          .update(updatedFlashcard.toMap());

      print('Flashcard updated successfully');
    } catch (e) {
      print('Error updating flashcard: $e');
      rethrow;
    }
  }

  /// Delete a flashcard
  /// Removes the flashcard and updates stats
  Future<void> deleteFlashcard(String userId, String flashcardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(flashcardId)
          .delete();

      // Update stats - decrement flashcard count
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .update({'totalFlashcards': FieldValue.increment(-1)});

      print('Flashcard deleted successfully');
    } catch (e) {
      print('Error deleting flashcard: $e');
      rethrow;
    }
  }

  /// Delete multiple flashcards in batch
  /// Efficiently deletes multiple flashcards
  Future<void> bulkDeleteFlashcards(
    String userId,
    List<String> flashcardIds,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final flashcardId in flashcardIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('flashcards')
            .doc(flashcardId);

        batch.delete(docRef);
      }

      await batch.commit();

      // Update stats
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .update({
            'totalFlashcards': FieldValue.increment(-flashcardIds.length),
          });

      print('${flashcardIds.length} flashcards deleted successfully');
    } catch (e) {
      print('Error bulk deleting flashcards: $e');
      rethrow;
    }
  }

  /// Get flashcard count for a user
  /// Useful for statistics
  Future<int> getFlashcardCount(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('Error getting flashcard count: $e');
      return 0;
    }
  }

  /// Get flashcards that need review (less reviewed and higher difficulty)
  /// Implements spaced repetition by suggesting cards to review
  Future<List<Flashcard>> getFlashcardsForReview(String userId) async {
    try {
      final allFlashcards = await getAllFlashcards(userId);

      // Sort by: times reviewed (ascending), then difficulty (descending)
      allFlashcards.sort((a, b) {
        final reviewComparison = a.timesReviewed.compareTo(b.timesReviewed);
        if (reviewComparison != 0) return reviewComparison;
        return b.difficulty.compareTo(a.difficulty);
      });

      // Return top 20 cards for review
      return allFlashcards.take(20).toList();
    } catch (e) {
      print('Error getting flashcards for review: $e');
      return [];
    }
  }

  /// Get study stats including flashcard-related metrics
  /// Enhanced version that includes flashcard-specific data
  Future<Map<String, dynamic>> getFlashcardStats(String userId) async {
    try {
      final allFlashcards = await getAllFlashcards(userId);
      final markedFlashcards = allFlashcards.where((c) => c.isMarked).length;
      final totalReviews = allFlashcards.fold<int>(
        0,
        (sum, card) => sum + card.timesReviewed,
      );

      final difficultyDistribution = <int, int>{};
      for (final card in allFlashcards) {
        difficultyDistribution[card.difficulty] =
            (difficultyDistribution[card.difficulty] ?? 0) + 1;
      }

      return {
        'totalFlashcards': allFlashcards.length,
        'markedFlashcards': markedFlashcards,
        'totalReviews': totalReviews,
        'averageReviews': allFlashcards.isNotEmpty
            ? (totalReviews / allFlashcards.length).toStringAsFixed(2)
            : '0',
        'difficultyDistribution': difficultyDistribution,
      };
    } catch (e) {
      print('Error getting flashcard stats: $e');
      return {};
    }
  }
}
