import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static final AIService _instance = AIService._internal();

  // Free API options:
  // 1. Together.ai: https://www.together.ai (generous free tier)
  // 2. Hugging Face: https://huggingface.co/inference-api (free tier)
  // 3. Local mock implementation (below)

  // Using mock implementation for demonstration (works without API key)
  // To use real APIs, uncomment the respective method below

  static const String _togetherApiKey =
      'YOUR_TOGETHER_AI_API_KEY'; // Get free at together.ai
  static const String _huggingFaceApiKey =
      'YOUR_HUGGING_FACE_API_KEY'; // Get free at huggingface.co

  AIService._internal();

  factory AIService() {
    return _instance;
  }

  /// Summarize text using mock implementation (works without API key)
  /// For production, replace with Together.ai or Hugging Face implementation
  Future<String> summarizeText(String text, {int maxLength = 150}) async {
    try {
      if (text.isEmpty) {
        throw Exception('Text cannot be empty');
      }

      // Mock summarization using simple text processing
      return _generateMockSummary(text, maxLength);

      // Uncomment below to use real APIs:
      // return await _summarizeWithTogether(text, maxLength);
      // return await _summarizeWithHuggingFace(text, maxLength);
    } catch (e) {
      print('Error summarizing text: $e');
      throw Exception('Failed to summarize: $e');
    }
  }

  /// Simple mock summarization (no API key needed)
  String _generateMockSummary(String text, int maxLength) {
    // Split into sentences
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      return text.substring(0, (text.length / 2).toInt());
    }

    // Select key sentences based on keywords
    List<String> summary = [];
    int wordCount = 0;

    for (var sentence in sentences) {
      int sentenceWords = sentence.split(' ').length;
      if (wordCount + sentenceWords <= maxLength) {
        summary.add(sentence);
        wordCount += sentenceWords;
      } else if (summary.isEmpty) {
        // Add first sentence regardless of length
        summary.add(sentence);
        break;
      } else {
        break;
      }
    }

    return summary.join('. ').trim() + '.';
  }

  /// Summarize using Together.ai free API
  /// Sign up at: https://www.together.ai (free tier available)
  /// Uncomment the call in summarizeText() to enable this
  // ignore: unused_element
  Future<String> _summarizeWithTogether(String text, int maxLength) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.together.xyz/inference'),
        headers: {
          'Authorization': 'Bearer $_togetherApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'togethercomputer/llama-2-7b-chat',
          'prompt': 'Summarize this in $maxLength words:\n\n$text\n\nSummary:',
          'max_tokens': maxLength,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output']['choices'][0]['text'].trim();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error with Together.ai: $e');
      // Fallback to mock implementation
      return _generateMockSummary(text, maxLength);
    }
  }

  /// Summarize using Hugging Face Inference API
  /// Sign up at: https://huggingface.co/inference-api (free tier available)
  /// Uncomment the call in summarizeText() to enable this
  // ignore: unused_element
  Future<String> _summarizeWithHuggingFace(String text, int maxLength) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://api-inference.huggingface.co/models/facebook/bart-large-cnn',
        ),
        headers: {'Authorization': 'Bearer $_huggingFaceApiKey'},
        body: jsonEncode({
          'inputs': text,
          'parameters': {'max_length': maxLength, 'min_length': 30},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['summary_text'].trim();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error with Hugging Face: $e');
      // Fallback to mock implementation
      return _generateMockSummary(text, maxLength);
    }
  }

  /// Generate flashcards from text using mock implementation
  /// Returns JSON formatted flashcard data
  Future<String> generateFlashcards(String text, {int cardCount = 5}) async {
    try {
      if (text.isEmpty) {
        throw Exception('Text cannot be empty');
      }

      // Mock flashcard generation
      return _generateMockFlashcards(text, cardCount);

      // Uncomment below to use real APIs with LLM:
      // return await _generateFlashcardsWithTogether(text, cardCount);
    } catch (e) {
      print('Error generating flashcards: $e');
      throw Exception('Failed to generate flashcards: $e');
    }
  }

  /// Generate mock flashcards (no API key needed)
  String _generateMockFlashcards(String text, int cardCount) {
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    List<Map<String, String>> flashcards = [];

    for (
      int i = 0;
      i < sentences.length && flashcards.length < cardCount;
      i++
    ) {
      final sentence = sentences[i];
      if (sentence.length > 10) {
        // Create question and answer from sentence
        final question =
            'What is the main idea in: "${sentence.substring(0, (sentence.length / 2).toInt())}"?';
        final answer = sentence;

        flashcards.add({'question': question, 'answer': answer});
      }
    }

    return jsonEncode({'flashcards': flashcards});
  }

  /// Generate flashcards using Together.ai API
  /// Uncomment the call in generateFlashcards() to enable this
  // ignore: unused_element
  Future<String> _generateFlashcardsWithTogether(
    String text,
    int cardCount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.together.xyz/inference'),
        headers: {
          'Authorization': 'Bearer $_togetherApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'togethercomputer/llama-2-7b-chat',
          'prompt':
              'Create $cardCount flashcards from this text. Return as JSON with "flashcards" array containing "question" and "answer" fields:\n\n$text',
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output']['choices'][0]['text'].trim();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error with Together.ai flashcards: $e');
      return _generateMockFlashcards(text, cardCount);
    }
  }
}
