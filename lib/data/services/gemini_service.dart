import 'dart:convert';
import 'dart:io';

class GeminiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  GeminiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory GeminiMessage.fromJson(Map<String, dynamic> json) => GeminiMessage(
        text: json['text'] as String,
        isUser: json['isUser'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
      );
}

class GeminiService {
  static const String defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const List<String> candidateModels = [
    'gemini-2.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3-flash-preview',
  ];

  final String _apiKey;

  GeminiService({String? apiKey}) : _apiKey = apiKey ?? defaultApiKey;

  Future<String> askGemini({
    required String prompt,
    String? liveContext,
    List<GeminiMessage>? conversationHistory,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Gemini API key is not configured. Please supply your API key via `--dart-define=GEMINI_API_KEY=your_key` to activate the AI Tutor.';
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {

      final List<Map<String, dynamic>> contents = [];

      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final recent = conversationHistory.length > 4
            ? conversationHistory.sublist(conversationHistory.length - 4)
            : conversationHistory;

        for (final msg in recent) {
          if (!msg.isError) {
            contents.add({
              'role': msg.isUser ? 'user' : 'model',
              'parts': [
                {'text': msg.text}
              ],
            });
          }
        }
      }

      String fullPrompt = prompt;
      if (liveContext != null && liveContext.trim().isNotEmpty) {
        fullPrompt = '[LIVE EXPERIMENT CONTEXT]\n$liveContext\n\n[USER QUESTION]\n$prompt';
      }

      contents.add({
        'role': 'user',
        'parts': [
          {'text': fullPrompt}
        ],
      });

      final Map<String, dynamic> requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {
              'text': 'You are Gemini AI Tutor, an enthusiastic, world-class Deep Learning and Neural Network interactive mentor inside Visual Neural Network Lab.\n'
                  'Your mission is to make neural networks, calculus, backpropagation, activation functions, loss surfaces, regularization, and vision architectures intuitive, engaging, and crystal clear.\n\n'
                  'CRITICAL SPEED & FORMATTING RULES:\n'
                  '- Deliver answers in 3-4 punchy, structured sections using bold markdown headers (###), bullet points (*), and inline code (`code`).\n'
                  '- ALWAYS complete your thought and every equation; NEVER stop mid-sentence.\n'
                  '- Keep answers punchy, educational, and under 250 words total so they generate fast.\n'
                  '- When writing math, use clean Unicode text or inline code (do NOT use LaTeX dollar signs like \$x\$, write x or x_i instead).\n'
                  '- If the user provides Live Experiment Context (e.g., dataset, loss, epochs, layers), diagnose their training run with specific actionable tips.'
            }
          ]
        },
        'generationConfig': {
          'temperature': 0.35,
          'maxOutputTokens': 900,
        }
      };

      Exception? lastException;
      for (int i = 0; i < candidateModels.length; i++) {
        final model = candidateModels[i];
        try {
          return await _makeRequest(client, model, requestBody);
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          final errStr = e.toString();
          final bool isRetryable = errStr.contains('503') || errStr.contains('404') || errStr.contains('429') || errStr.contains('timed out') || errStr.contains('TimeoutException');

          if (isRetryable && i < candidateModels.length - 1) {

            continue;
          }
          break;
        }
      }

      final errorMsg = lastException != null
          ? lastException.toString().replaceAll(_apiKey, '[PROTECTED_KEY]').replaceAll('Exception: ', '').replaceAll('HttpException: ', '')
          : 'Unable to connect to Gemini.';
      throw HttpException(errorMsg);
    } finally {
      client.close();
    }
  }

  Future<String> _makeRequest(
    HttpClient client,
    String model,
    Map<String, dynamic> requestBody,
  ) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
    );

    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    final jsonBytes = utf8.encode(jsonEncode(requestBody));
    request.contentLength = jsonBytes.length;
    request.add(jsonBytes);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
      return 'Received an empty response from Gemini.';
    } else {
      String errorMessage = 'API Error (${response.statusCode})';
      try {
        final errorJson = jsonDecode(responseBody) as Map<String, dynamic>;
        final error = errorJson['error'] as Map<String, dynamic>?;
        if (error != null && error['message'] != null) {
          errorMessage = error['message'] as String;
        }
      } catch (_) {}
      final sanitized = errorMessage.replaceAll(_apiKey, '[PROTECTED_KEY]');
      throw HttpException('$sanitized (Status: ${response.statusCode})');
    }
  }
}
