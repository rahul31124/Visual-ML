import 'package:flutter/material.dart';
import '../../data/services/gemini_service.dart';

class GeminiProvider extends ChangeNotifier {
  final GeminiService _service = GeminiService();

  final List<GeminiMessage> _messages = [];
  bool _isLoading = false;
  bool _isLiveContextEnabled = true;

  GeminiProvider() {
    _initDefaultMessage();
  }

  void _initDefaultMessage() {
    _messages.add(
      GeminiMessage(
        text: 'Hello! I am your Gemini AI Deep Learning Mentor.\n\n'
            'Ask me anything about how neural networks work, calculus & backpropagation, activation functions, loss landscapes, or vision architectures (LeNet-5, ResNet).\n\n'
            'Tip: Keep "Attach Live Lab Context" enabled so I can automatically diagnose your current active studio experiment in real time!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  List<GeminiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isLiveContextEnabled => _isLiveContextEnabled;

  void toggleLiveContext() {
    _isLiveContextEnabled = !_isLiveContextEnabled;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initDefaultMessage();
    notifyListeners();
  }

  Future<void> askQuestion({
    required String question,
    String? liveContext,
  }) async {
    final cleanPrompt = question.trim();
    if (cleanPrompt.isEmpty || _isLoading) return;

    _messages.add(
      GeminiMessage(
        text: cleanPrompt,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _isLoading = true;
    notifyListeners();

    try {
      final contextToSend = _isLiveContextEnabled ? liveContext : null;
      final responseText = await _service.askGemini(
        prompt: cleanPrompt,
        liveContext: contextToSend,
        conversationHistory: _messages.sublist(0, _messages.length - 1),
      );

      _messages.add(
        GeminiMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _messages.add(
        GeminiMessage(
          text: 'Error getting answer from Gemini: ${e.toString().replaceAll('HttpException: ', '')}\n\n'
              'Please check your internet connection and try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deepDiveTopic(String topicTitle, {String? liveContext}) async {
    final prompt = 'Provide a fast, visual 3-part breakdown of "$topicTitle":\n'
        '1. Intuitive Analogy (1 sentence)\n'
        '2. Core Math / Mechanism (2-3 sentences with formulas)\n'
        '3. Practical Studio Tip\n'
        'Keep it punchy, complete every sentence cleanly, and stay under 200 words.';
    await askQuestion(question: prompt, liveContext: liveContext);
  }
}
