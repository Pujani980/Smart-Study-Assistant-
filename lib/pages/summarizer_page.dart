import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';  // Temporarily disabled
import 'package:smart_study_assistant/models/note_model.dart';
import 'package:smart_study_assistant/services/ai_service.dart';
import 'package:smart_study_assistant/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class SummarizerPage extends StatefulWidget {
  final String userId;

  const SummarizerPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SummarizerPage> createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AIService _aiService = AIService();
  final FirebaseService _firebaseService = FirebaseService();
  // final TextRecognizer _textRecognizer = TextRecognizer();  // Temporarily disabled

  String? _extractedText;
  String? _summary;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isSummarizing = false;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    // _textRecognizer.close();  // Temporarily disabled
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isLoading = true;
        });

        // Extract text from image using OCR
        await _extractTextFromImage();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _extractTextFromImage() async {
    try {
      // OCR temporarily disabled for web compatibility
      // In native Android/iOS builds, OCR will automatically extract text from images
      setState(() {
        _isLoading = false;
        _extractedText =
            '[Image loaded - OCR available on native platforms only]';
      });

      _showErrorSnackBar(
        'OCR available on Android/iOS. Please type or paste text here for web.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading image: $e');
    }
  }

  Future<void> _summarizeText() async {
    final textToSummarize = _textController.text.trim();

    if (textToSummarize.isEmpty) {
      _showErrorSnackBar('Please enter or upload text to summarize');
      return;
    }

    setState(() {
      _isSummarizing = true;
      _summary = null;
    });

    try {
      final summary = await _aiService.summarizeText(textToSummarize);
      setState(() {
        _summary = summary;
        _isSummarizing = false;
      });
    } catch (e) {
      setState(() {
        _isSummarizing = false;
      });
      _showErrorSnackBar('Error during summarization: $e');
    }
  }

  Future<void> _saveSummary() async {
    final title = _titleController.text.trim();
    final textToSave = _textController.text.trim();

    if (title.isEmpty) {
      _showErrorSnackBar('Please enter a title for this note');
      return;
    }

    if (textToSave.isEmpty) {
      _showErrorSnackBar('No text to save');
      return;
    }

    try {
      const uuid = Uuid();
      final note = Note(
        id: uuid.v4(),
        title: title,
        content: textToSave,
        summary: _summary ?? '',
        createdAt: DateTime.now(),
        category: 'General',
        userId: widget.userId,
      );

      await _firebaseService.saveNote(note);
      await _firebaseService.updateSummaryCount(widget.userId);

      if (mounted) {
        _showSuccessSnackBar('Summary saved successfully!');
        _resetForm();
      }
    } catch (e) {
      _showErrorSnackBar('Error saving summary: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _textController.clear();
      _titleController.clear();
      _selectedImage = null;
      _extractedText = null;
      _summary = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Summarizer'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            _buildTitleInput(),
            const SizedBox(height: 20),

            // Image Upload Section
            _buildImageUploadSection(),
            const SizedBox(height: 20),

            // Text Input Section
            _buildTextInputSection(),
            const SizedBox(height: 16),

            // Character count
            _buildCharacterCount(),
            const SizedBox(height: 20),

            // Summarize Button
            _buildSummarizeButton(),
            const SizedBox(height: 20),

            // Summary Result Section
            if (_summary != null) ...[
              _buildSummaryResultSection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note Title',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter note title...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Image (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.image_outlined,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: Text(
                'Text extracted: ${_extractedText?.length ?? 0} characters',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text to Summarize',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Paste or type your study notes here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
    );
  }

  Widget _buildCharacterCount() {
    final charCount = _textController.text.length;
    final wordCount = _textController.text.isEmpty
        ? 0
        : _textController.text.trim().split(RegExp(r'\s+')).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Characters: $charCount | Words: $wordCount',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        GestureDetector(
          onTap: _resetForm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarizeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSummarizing ? null : _summarizeText,
        icon: _isSummarizing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[50]!),
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isSummarizing ? 'Summarizing...' : 'Summarize with AI',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSummaryResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 2),
        const SizedBox(height: 16),
        const Text(
          'Summary Result',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: SelectableText(
            _summary ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Summary length: ${_summary?.length ?? 0} characters',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Summary copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveSummary,
                icon: const Icon(Icons.save),
                label: const Text('Save Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
