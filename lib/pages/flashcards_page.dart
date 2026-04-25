import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_study_assistant/models/note_model.dart';
import 'package:smart_study_assistant/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

/// Main Flashcards Page
/// Displays flashcard sets created from notes/summaries
/// Features: Auto-generated flashcards, manual creation, flip animations, progress tracking
class FlashcardsPage extends StatefulWidget {
  final String? userId;

  const FlashcardsPage({Key? key, this.userId}) : super(key: key);

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  static const Duration _autoFlipBackDelay = Duration(seconds: 5);
  static const Duration _flipAnimationDuration = Duration(milliseconds: 450);
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();
  final GlobalKey<FlipCardState> _flipCardKey = GlobalKey<FlipCardState>();
  List<Flashcard> allFlashcards = [];
  List<Flashcard> currentFlashcards = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool hasError = false;
  String? selectedNoteId;
  String filterDifficulty = 'All';
  bool showOnlyMarked = false;
  bool isShuffled = false;
  late String userId;
  bool _isCardFront = true;
  bool _isAnimating = false;
  Timer? _autoFlipTimer;
  Timer? _animationGuardTimer;
  StreamSubscription<List<Flashcard>>? _flashcardsSubscription;

  @override
  void initState() {
    super.initState();
    userId = widget.userId ?? 'test_user';
    _subscribeToFlashcards();
  }

  /// Use a StreamSubscription instead of StreamBuilder so data updates
  /// go through a proper setState call and never run as builder side-effects.
  void _subscribeToFlashcards() {
    try {
      final stream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .snapshots()
          .map((snapshot) {
            final cards = snapshot.docs
                .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
                .toList();
            cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return cards;
          });

      _flashcardsSubscription = stream.listen(
        (cards) {
          if (!mounted) return;
          setState(() {
            allFlashcards = cards;
            isLoading = false;
            hasError = false;
            _applyFilters();
          });
        },
        onError: (error) {
          print('⚠️ Firestore error: $error');
          if (!mounted) return;
          setState(() {
            // Fall back to demo data on error
            allFlashcards = _getDemoFlashcards();
            isLoading = false;
            hasError = false;
            _applyFilters();
          });
        },
      );
    } catch (e) {
      print('Stream creation error: $e');
      setState(() {
        allFlashcards = _getDemoFlashcards();
        isLoading = false;
        _applyFilters();
      });
    }
  }



  /// Fallback list with demo flashcards when Firebase is unavailable
  List<Flashcard> _getDemoFlashcards() {
    final demoCards = [
      Flashcard(
        id: 'demo_card_1',
        question: 'What is Flutter?',
        answer:
            'Flutter is Google\'s open-source framework for building beautiful, natively compiled applications from a single codebase.',
        noteId: 'demo_1',
        userId: userId,
        difficulty: 2,
        isMarked: false,
        timesReviewed: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Flashcard(
        id: 'demo_card_2',
        question: 'What is Firestore?',
        answer:
            'Firestore is a cloud-hosted NoSQL database that provides real-time data synchronization and offline support for modern applications.',
        noteId: 'demo_2',
        userId: userId,
        difficulty: 3,
        isMarked: false,
        timesReviewed: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Flashcard(
        id: 'demo_card_3',
        question: 'What is spaced repetition?',
        answer:
            'Spaced repetition is a learning technique where you review material at increasing intervals to improve long-term retention.',
        noteId: 'demo_3',
        userId: userId,
        difficulty: 2,
        isMarked: false,
        timesReviewed: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    return demoCards;
  }

  void _applyFilters({bool resetCardFace = false}) {
    if (resetCardFace) {
      _cancelAutoFlipTimer();
      _ensureCardFront();
    }

    String? previousCardId;
    if (currentFlashcards.isNotEmpty &&
        currentIndex >= 0 &&
        currentIndex < currentFlashcards.length) {
      previousCardId = currentFlashcards[currentIndex].id;
    }

    final selectedDifficulty = _selectedDifficultyLevel();

    final filteredCards = allFlashcards.where((card) {
      // Filter by note
      if (selectedNoteId != null && card.noteId != selectedNoteId) {
        return false;
      }

      // Filter by difficulty
      if (selectedDifficulty != null && card.difficulty != selectedDifficulty) {
        return false;
      }

      // Filter by marked status
      if (showOnlyMarked && !card.isMarked) {
        return false;
      }

      return true;
    }).toList();

    currentFlashcards = filteredCards;

    if (currentFlashcards.isEmpty) {
      currentIndex = 0;
      return;
    }

    if (previousCardId != null) {
      final newIndex = currentFlashcards.indexWhere(
        (c) => c.id == previousCardId,
      );
      if (newIndex != -1) {
        currentIndex = newIndex;
        return;
      }
    }

    if (currentIndex >= currentFlashcards.length) {
      currentIndex = currentFlashcards.length - 1;
    }

    if (currentIndex < 0) {
      currentIndex = 0;
    }
  }

  int? _selectedDifficultyLevel() {
    if (filterDifficulty == 'All') {
      return null;
    }

    return _parseDifficultyFilterValue(filterDifficulty);
  }

  int? _parseDifficultyFilterValue(String value) {
    final normalized = value.trim().toLowerCase();

    const labelMap = {
      'easy': 1,
      'medium': 3,
      'hard': 5,
      'very easy': 1,
      'very hard': 5,
    };

    if (labelMap.containsKey(normalized)) {
      return labelMap[normalized];
    }

    final numeric = int.tryParse(normalized);
    if (numeric == null) {
      return null;
    }

    return numeric.clamp(1, 5);
  }

  String _difficultyLabel(String value) {
    if (value == 'All') {
      return 'All Difficulties';
    }

    return 'Level $value';
  }

  void _shuffleCards() {
    _cancelAutoFlipTimer();
    _ensureCardFront();
    setState(() {
      currentFlashcards.shuffle();
      isShuffled = !isShuffled;
      currentIndex = 0;
    });
  }

  void _ensureCardFront() {
    if (!_isCardFront) {
      _flipCardKey.currentState?.toggleCard();
      _isCardFront = true;
    }
  }

  void _cancelAutoFlipTimer() {
    _autoFlipTimer?.cancel();
    _autoFlipTimer = null;
  }

  void _cancelAnimationGuard() {
    _animationGuardTimer?.cancel();
    _animationGuardTimer = null;
  }

  void _onQuestionTapped(String cardId) {
    // Block re-taps while the flip animation is still running
    if (_isAnimating) return;

    _cancelAutoFlipTimer();

    // Flip the card and track direction
    _isAnimating = true;
    _flipCardKey.currentState?.toggleCard();
    _isCardFront = !_isCardFront;

    if (!_isCardFront) {
      // Flipped to show answer.
      // IMPORTANT: delay the Firestore write until AFTER the animation is done
      // so that the stream update (which causes setState) never fires while the
      // flip animation is still in progress.
      _animationGuardTimer = Timer(_flipAnimationDuration, () {
        _isAnimating = false;
        if (!mounted) return;
        _incrementReviewCount(); // safe to write now – animation is complete

        // Start 5-second countdown to auto-flip back
        _autoFlipTimer = Timer(_autoFlipBackDelay, () {
          if (!mounted) return;
          final isSameCardVisible =
              currentFlashcards.isNotEmpty &&
              currentIndex >= 0 &&
              currentIndex < currentFlashcards.length &&
              currentFlashcards[currentIndex].id == cardId;

          if (isSameCardVisible && !_isCardFront) {
            _isAnimating = true;
            _flipCardKey.currentState?.toggleCard();
            _isCardFront = true;
            _animationGuardTimer?.cancel();
            _animationGuardTimer = Timer(_flipAnimationDuration, () {
              _isAnimating = false;
            });
          }
        });
      });
    } else {
      // Flipped back to show question
      _animationGuardTimer?.cancel();
      _animationGuardTimer = Timer(_flipAnimationDuration, () {
        _isAnimating = false;
      });
    }
  }

  void _showFlashcardMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleMarkCard() async {
    final card = currentFlashcards[currentIndex];
    final updatedCard = card.copyWith(isMarked: !card.isMarked);

    await _firebaseService.updateFlashcard(updatedCard);

    setState(() {
      allFlashcards[allFlashcards.indexWhere((c) => c.id == card.id)] =
          updatedCard;
      currentFlashcards[currentIndex] = updatedCard;
    });
  }

  Future<void> _deleteCard() async {
    final userId = widget.userId ?? 'test_user';
    final card = currentFlashcards[currentIndex];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firebaseService.deleteFlashcard(userId, card.id);

      setState(() {
        allFlashcards.removeWhere((c) => c.id == card.id);
        _applyFilters();
      });

      _showFlashcardMessage('Flashcard deleted successfully');
    }
  }

  Future<void> _updateDifficulty(int newDifficulty) async {
    final card = currentFlashcards[currentIndex];
    final updatedCard = card.copyWith(difficulty: newDifficulty);

    await _firebaseService.updateFlashcard(updatedCard);

    setState(() {
      allFlashcards[allFlashcards.indexWhere((c) => c.id == card.id)] =
          updatedCard;
      currentFlashcards[currentIndex] = updatedCard;
    });
  }

  Future<void> _incrementReviewCount() async {
    if (currentIndex < 0 || currentIndex >= currentFlashcards.length) return;
    final card = currentFlashcards[currentIndex];
    final updatedCard = card.copyWith(timesReviewed: card.timesReviewed + 1);
    // Only write to Firestore – do NOT call setState here.
    // The StreamSubscription listener will receive the update and call
    // setState itself, safely updating the UI without touching the flip animation.
    await _firebaseService.updateFlashcard(updatedCard);
  }

  Future<void> _showCreateCardDialog() async {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Enter the question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  hintText: 'Enter the answer',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (questionController.text.isNotEmpty &&
                  answerController.text.isNotEmpty) {
                final userId = widget.userId ?? 'test_user';
                final newCard = Flashcard(
                  id: _uuid.v4(),
                  question: questionController.text,
                  answer: answerController.text,
                  noteId: selectedNoteId ?? 'manual',
                  userId: userId,
                  createdAt: DateTime.now(),
                );

                await _firebaseService.saveFlashcard(newCard);

                setState(() {
                  allFlashcards.add(newCard);
                  // Reset filters so user can see all created cards.
                  filterDifficulty = 'All';
                  showOnlyMarked = false;
                  selectedNoteId = null;
                  _applyFilters();

                  final newCardIndex = currentFlashcards.indexWhere(
                    (c) => c.id == newCard.id,
                  );
                  if (newCardIndex != -1) {
                    currentIndex = newCardIndex;
                  }
                });

                Navigator.pop(context);

                // Intentionally no success popup after create.
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (hasError) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading flashcards'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    } else {
      body = currentFlashcards.isEmpty
          ? _buildEmptyState()
          : _buildFlashcardView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        elevation: 0,
        actions: [
          if (currentFlashcards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${currentIndex + 1} / ${currentFlashcards.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCardDialog,
        label: const Text('New Card'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Flashcards Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create flashcards to start studying',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardView() {
    final card = currentFlashcards[currentIndex];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters section
            _buildFiltersBar(),
            const SizedBox(height: 24),

            // Main Flashcard with Flip Animation
            GestureDetector(
              onTap: () => _onQuestionTapped(card.id),
              child: FlipCard(
                key: _flipCardKey,
                flipOnTouch: false,
                direction: FlipDirection.HORIZONTAL,
                speed: 400,
                front: _buildCardFace(
                  color: Colors.blue[700],
                  title: 'Question',
                  content: card.question,
                ),
                back: _buildCardFace(
                  color: Colors.green[700],
                  title: 'Answer',
                  content: card.answer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card stats
            _buildCardStats(card),
            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(card),
            const SizedBox(height: 16),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Shuffle button
          ElevatedButton.icon(
            onPressed: _shuffleCards,
            icon: Icon(isShuffled ? Icons.shuffle_on : Icons.shuffle),
            label: const Text('Shuffle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isShuffled ? Colors.orange : null,
            ),
          ),
          const SizedBox(width: 8),

          // Difficulty filter
          DropdownButton<String>(
            value: filterDifficulty,
            items: ['All', '1', '2', '3', '4', '5']
                .map(
                  (difficulty) => DropdownMenuItem(
                    value: difficulty,
                    child: Text(_difficultyLabel(difficulty)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                filterDifficulty = value ?? 'All';
                _applyFilters(resetCardFace: true);
              });
            },
          ),
          const SizedBox(width: 8),

          // Show marked filter
          FilterChip(
            label: const Text('Marked Only'),
            selected: showOnlyMarked,
            onSelected: (selected) {
              setState(() {
                showOnlyMarked = selected;
                _applyFilters(resetCardFace: true);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace({
    required Color? color,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStats(Flashcard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.repeat,
            label: 'Reviewed',
            value: '${card.timesReviewed}',
          ),
          _buildStatItem(
            icon: Icons.schedule,
            label: 'Created',
            value: _formatDate(card.createdAt),
          ),
          _buildStatItem(
            icon: Icons.flag,
            label: 'Marked',
            value: card.isMarked ? 'Yes' : 'No',
            valueColor: card.isMarked ? Colors.orange : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }



  Widget _buildActionButtons(Flashcard card) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleMarkCard,
            icon: Icon(card.isMarked ? Icons.star : Icons.star_outline),
            label: Text(card.isMarked ? 'Unmark' : 'Mark'),
            style: ElevatedButton.styleFrom(
              backgroundColor: card.isMarked ? Colors.orange : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _deleteCard,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: currentIndex > 0
                ? () {
                    _cancelAutoFlipTimer();
                    _ensureCardFront();
                    setState(() {
                      currentIndex--;
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: currentIndex < currentFlashcards.length - 1
                ? () {
                    _cancelAutoFlipTimer();
                    _ensureCardFront();
                    setState(() {
                      currentIndex++;
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays ~/ 7)}w ago';
    }
  }

  @override
  void dispose() {
    _cancelAutoFlipTimer();
    _cancelAnimationGuard();
    _flashcardsSubscription?.cancel();
    super.dispose();
  }
}
