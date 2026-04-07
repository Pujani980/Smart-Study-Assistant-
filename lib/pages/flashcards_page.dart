import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:smart_study_assistant/models/note_model.dart';
import 'package:smart_study_assistant/services/firebase_service.dart';
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
  final FirebaseService _firebaseService = FirebaseService();
  List<Flashcard> allFlashcards = [];
  List<Flashcard> currentFlashcards = [];
  int currentIndex = 0;
  bool isLoading = true;
  String? selectedNoteId;
  String filterDifficulty = 'All';
  bool showOnlyMarked = false;
  bool isShuffled = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => isLoading = true);
    final userId = widget.userId ?? 'test_user'; // Replace with actual user ID
    final flashcards = await _firebaseService.getAllFlashcards(userId);

    setState(() {
      allFlashcards = flashcards;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    currentFlashcards = allFlashcards.where((card) {
      // Filter by note
      if (selectedNoteId != null && card.noteId != selectedNoteId) {
        return false;
      }

      // Filter by difficulty
      if (filterDifficulty != 'All') {
        final difficultyLevel = int.tryParse(filterDifficulty) ?? 3;
        if (card.difficulty != difficultyLevel) return false;
      }

      // Filter by marked status
      if (showOnlyMarked && !card.isMarked) {
        return false;
      }

      return true;
    }).toList();

    currentIndex = 0;
  }

  void _shuffleCards() {
    setState(() {
      currentFlashcards.shuffle();
      isShuffled = !isShuffled;
      currentIndex = 0;
    });
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updatedCard.isMarked ? 'Card marked!' : 'Mark removed!'),
        duration: const Duration(milliseconds: 800),
      ),
    );
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Flashcard deleted')));
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Difficulty set to $newDifficulty/5')),
    );
  }

  Future<void> _incrementReviewCount() async {
    final card = currentFlashcards[currentIndex];
    final updatedCard = card.copyWith(timesReviewed: card.timesReviewed + 1);

    await _firebaseService.updateFlashcard(updatedCard);

    setState(() {
      allFlashcards[allFlashcards.indexWhere((c) => c.id == card.id)] =
          updatedCard;
      currentFlashcards[currentIndex] = updatedCard;
    });
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
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  question: questionController.text,
                  answer: answerController.text,
                  noteId: selectedNoteId ?? 'manual',
                  userId: userId,
                  createdAt: DateTime.now(),
                );

                await _firebaseService.saveFlashcard(newCard);

                setState(() {
                  allFlashcards.add(newCard);
                  _applyFilters();
                });

                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Flashcard created successfully! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.green[600],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentFlashcards.isEmpty
          ? _buildEmptyState()
          : _buildFlashcardView(),
      bottomNavigationBar: _buildBottomBar(),
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
            FlipCard(
              direction: FlipDirection.HORIZONTAL,
              speed: 400,
              onFlip: () {
                _incrementReviewCount();
                // Log that card was reviewed
              },
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
            const SizedBox(height: 16),

            // Card stats
            _buildCardStats(card),
            const SizedBox(height: 24),

            // Difficulty selector
            _buildDifficultySelector(card),
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
                    child: Text('Difficulty: $difficulty'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                filterDifficulty = value ?? 'All';
                _applyFilters();
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
                _applyFilters();
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

  Widget _buildDifficultySelector(Flashcard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty Level', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = card.difficulty == level;
            return InkWell(
              onTap: () => _updateDifficulty(level),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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
                ? () => setState(() => currentIndex--)
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: currentIndex < currentFlashcards.length - 1
                ? () => setState(() => currentIndex++)
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: _loadFlashcards,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Show statistics dialog
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('Stats'),
            ),
          ],
        ),
      ),
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
    super.dispose();
  }
}
