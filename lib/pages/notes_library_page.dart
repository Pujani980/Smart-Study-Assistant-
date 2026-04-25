import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_study_assistant/models/note_model.dart';
import 'package:smart_study_assistant/services/firebase_service.dart';
import 'package:intl/intl.dart';

class NotesLibraryPage extends StatefulWidget {
  final String userId;

  const NotesLibraryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotesLibraryPage> createState() => _NotesLibraryPageState();
}

class _NotesLibraryPageState extends State<NotesLibraryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  DateTimeRange? _selectedDateRange;
  bool _isGridView = false;
  Set<String> _selectedNoteIds = {};

  final List<String> _categories = [
    'All',
    'General',
    'Mathematics',
    'Science',
    'Literature',
    'History',
    'Technology',
    'Business',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Note>> _getNotesStream() {
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Note.fromMap(doc.data(), doc.id))
              .toList())
          .handleError((error) {
            print('⚠️ Firestore error: $error');
            // Return empty stream on error - will be caught by StreamBuilder's error handler
          });
    } catch (e) {
      print('Stream creation error: $e');
      return Stream.value(_getDemoNotes());
    }
  }

  /// Fallback list with demo notes when Firebase is unavailable
  List<Note> _getDemoNotes() {
    final demoNotes = [
      Note(
        id: 'demo_1',
        title: 'Introduction to Flutter',
        content: 'Flutter is a cross-platform mobile development framework created by Google.',
        summary: 'Flutter: Framework for building beautiful, fast mobile apps.',
        category: 'Technology',
        userId: widget.userId,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Note(
        id: 'demo_2',
        title: 'Firebase Firestore Guide',
        content: 'Firestore is a cloud-hosted NoSQL database with real-time data sync.',
        summary: 'Firestore: Real-time database for scalable apps with offline support.',
        category: 'Technology',
        userId: widget.userId,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Note(
        id: 'demo_3',
        title: 'Study Tips for Exams',
        content: 'Effective study techniques: spaced repetition, active recall, and practice tests.',
        summary: 'Study smarter with proven techniques: space learning, test yourself, review often.',
        category: 'General',
        userId: widget.userId,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    return demoNotes;
  }

  /// Apply filters without calling setState - safe for use during build
  void _applyFiltersNoBuild() {
    final query = _searchController.text.toLowerCase();
    _filteredNotes = _allNotes.where((note) {
      bool matchesQuery = note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.summary.toLowerCase().contains(query);
      bool matchesCategory =
          _selectedCategory == 'All' ? true : note.category == _selectedCategory;
      bool matchesDateRange = _selectedDateRange == null
          ? true
          : (note.createdAt.isAfter(_selectedDateRange!.start) &&
              note.createdAt.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ));
      return matchesQuery && matchesCategory && matchesDateRange;
    }).toList();
  }

  /// Apply filters with setState - for user interactions
  void _filterNotes() {
    setState(() {
      _applyFiltersNoBuild();
    });
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _firebaseService.deleteNote(widget.userId, noteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }

  Future<void> _bulkDeleteNotes() async {
    try {
      final count = _selectedNoteIds.length;
      await _firebaseService.bulkDeleteNotes(
        widget.userId,
        _selectedNoteIds.toList(),
      );
      setState(() => _selectedNoteIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count note(s) deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting notes: $e')));
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picker = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picker != null) {
      setState(() => _selectedDateRange = picker);
      _filterNotes();
    }
  }

  void _showNoteDetails(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteDetailsSheet(
        note: note,
        onDelete: () {
          Navigator.pop(context);
          _deleteNote(note.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterMenu),
        ],
      ),
      // The search bar MUST live outside the StreamBuilder so it is never
      // recreated on Firestore updates — that was the root cause of the
      // cursor-disappearing bug.
      body: Column(
        children: [
          // ── Search bar (stable, never rebuilt by stream events) ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search notes by title...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // ── Notes list / grid (driven by Firestore stream) ───────────────
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 80, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading notes: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  );
                }

                _allNotes = snapshot.data ?? [];
                _applyFiltersNoBuild();

                return _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildGridView()
                        : _buildListView();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedNoteIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Notes'),
                    content: Text(
                      'Are you sure you want to delete ${_selectedNoteIds.length} note(s)?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _bulkDeleteNotes();
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete),
              label: Text('Delete ${_selectedNoteIds.length}'),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Category filter
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                    _filterNotes();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Date range filter
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _selectDateRange();
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _selectedDateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
              ),
            ),
            if (_selectedDateRange != null)
              TextButton(
                onPressed: () {
                  setState(() => _selectedDateRange = null);
                  _filterNotes();
                  Navigator.pop(context);
                },
                child: const Text('Clear Date Range'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No notes found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first note using the Summarizer',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return CustomScrollView(
      slivers: [
        // Notes count header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'All Notes (${_filteredNotes.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        // Notes list
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final note = _filteredNotes[index];
            final isSelected = _selectedNoteIds.contains(note.id);

            return NoteListCard(
              note: note,
              isSelected: isSelected,
              onToggleSelect: () {
                setState(() {
                  if (isSelected) {
                    _selectedNoteIds.remove(note.id);
                  } else {
                    _selectedNoteIds.add(note.id);
                  }
                });
              },
              onTap: _selectedNoteIds.isEmpty
                  ? () => _showNoteDetails(note)
                  : () {
                      setState(() {
                        if (isSelected) {
                          _selectedNoteIds.remove(note.id);
                        } else {
                          _selectedNoteIds.add(note.id);
                        }
                      });
                    },
              onLongPress: () {
                setState(() {
                  if (isSelected) {
                    _selectedNoteIds.remove(note.id);
                  } else {
                    _selectedNoteIds.add(note.id);
                  }
                });
              },
              onDelete: () => _deleteNote(note.id),
            );
          }, childCount: _filteredNotes.length),
        ),
        // Bottom padding
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: _selectedNoteIds.isNotEmpty ? 80 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return CustomScrollView(
      slivers: [
        // Notes count header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'All Notes (${_filteredNotes.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        // Notes grid
        SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            final note = _filteredNotes[index];
            final isSelected = _selectedNoteIds.contains(note.id);

            return NoteGridCard(
              note: note,
              isSelected: isSelected,
              onToggleSelect: () {
                setState(() {
                  if (isSelected) {
                    _selectedNoteIds.remove(note.id);
                  } else {
                    _selectedNoteIds.add(note.id);
                  }
                });
              },
              onTap: _selectedNoteIds.isEmpty
                  ? () => _showNoteDetails(note)
                  : () {
                      setState(() {
                        if (isSelected) {
                          _selectedNoteIds.remove(note.id);
                        } else {
                          _selectedNoteIds.add(note.id);
                        }
                      });
                    },
              onLongPress: () {
                setState(() {
                  if (isSelected) {
                    _selectedNoteIds.remove(note.id);
                  } else {
                    _selectedNoteIds.add(note.id);
                  }
                });
              },
              onDelete: () => _deleteNote(note.id),
            );
          }, childCount: _filteredNotes.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
        // Bottom padding
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: _selectedNoteIds.isNotEmpty ? 80 : 16,
            ),
          ),
        ),
      ],
    );
  }
}

// Note List Card Widget
class NoteListCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const NoteListCard({
    Key? key,
    required this.note,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  }) : super(key: key);

  Color _getCategoryColor() {
    switch (note.category) {
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'Literature':
        return Colors.purple;
      case 'History':
        return Colors.orange;
      case 'Technology':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }

  String _getCategoryInitial() {
    return note.category.isNotEmpty ? note.category[0].toUpperCase() : 'N';
  }

  String _getMetadata() {
    return 'Subject: ${note.category} | Modified: ${_formatDate(note.createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryInitial(),
                      style: TextStyle(
                        color: _getCategoryColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Note details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMetadata(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Today';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

// Note Grid Card Widget
class NoteGridCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const NoteGridCard({
    Key? key,
    required this.note,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue)
                  else
                    Icon(Icons.note, color: Colors.blue[300], size: 28),
                  const SizedBox(height: 8),
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      note.category,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.blue[100],
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (!isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Note Details Bottom Sheet
class _NoteDetailsSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const _NoteDetailsSheet({
    Key? key,
    required this.note,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    // Metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(label: Text(note.category)),
                        Text(
                          DateFormat('MMM d, yyyy').format(note.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Content section
                    if (note.content.isNotEmpty) ...[
                      Text(
                        'Content',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(note.content),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Summary section
                    if (note.summary.isNotEmpty) ...[
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(note.summary),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
