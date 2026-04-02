import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Supported cloud LLM providers — OpenAI-compatible REST APIs
enum ApiProvider {
  openAI('OpenAI', 'https://api.openai.com/v1'),
  groq('Groq', 'https://api.groq.com/openai/v1'),
  together('Together AI', 'https://api.together.xyz/v1'),
  openRouter('OpenRouter', 'https://openrouter.ai/api/v1'),
  custom('Custom', '');

  final String label;
  final String defaultBaseUrl;
  const ApiProvider(this.label, this.defaultBaseUrl);
}

/// Config for connecting to a cloud LLM API
class ApiConfig {
  final ApiProvider provider;
  final String apiKey;
  final String baseUrl;
  final String model;

  ApiConfig({
    required this.provider,
    required this.apiKey,
    String? baseUrl,
    required this.model,
  }) : baseUrl = baseUrl ?? provider.defaultBaseUrl;

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
      };

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      provider: ApiProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => ApiProvider.openAI,
      ),
      apiKey: json['apiKey'] ?? '',
      baseUrl: json['baseUrl'],
      model: json['model'] ?? 'gpt-3.5-turbo',
    );
  }
}

/// Default models per provider
class ApiProviderDefaults {
  static const Map<ApiProvider, List<String>> models = {
    ApiProvider.openAI: [
      'gpt-4o-mini',
      'gpt-4o',
      'gpt-4-turbo',
      'gpt-3.5-turbo',
    ],
    ApiProvider.groq: [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'mixtral-8x7b-32768',
      'gemma2-9b-it',
    ],
    ApiProvider.together: [
      'meta-llama/Llama-3.3-70B-Instruct-Turbo',
      'meta-llama/Llama-3.1-8B-Instruct-Turbo',
      'mistralai/Mixtral-8x7B-Instruct-v0.1',
      'Qwen/Qwen2.5-72B-Instruct-Turbo',
    ],
    ApiProvider.openRouter: [
      'meta-llama/llama-3.3-70b-instruct',
      'google/gemini-2.0-flash-001',
      'mistralai/mistral-large-latest',
      'anthropic/claude-3.5-sonnet',
    ],
    ApiProvider.custom: [],
  };
}

enum ApiLlmStatus { idle, connecting, streaming, error }

/// Service that talks to OpenAI-compatible cloud LLM APIs via HTTP
class ApiLlmService {
  ApiConfig? _config;
  ApiLlmStatus _status = ApiLlmStatus.idle;
  String? _errorMessage;
  HttpClient? _httpClient;
  bool _shouldStop = false;

  ApiLlmStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ApiConfig? get config => _config;
  bool get isConfigured => _config != null && _config!.apiKey.isNotEmpty;
  bool get isStreaming => _status == ApiLlmStatus.streaming;

  void configure(ApiConfig config) {
    _config = config;
    _errorMessage = null;
    _httpClient?.close(force: true);
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
    debugPrint('[API-LLM] Configured: ${config.provider.label} → ${config.model}');
  }

  /// Test the connection by making a lightweight models request
  Future<bool> testConnection() async {
    if (!isConfigured) {
      _errorMessage = 'API not configured';
      return false;
    }
    try {
      _status = ApiLlmStatus.connecting;
      final uri = Uri.parse('${_config!.baseUrl}/models');
      final request = await _getClient().getUrl(uri);
      request.headers.set('Authorization', 'Bearer ${_config!.apiKey}');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        _status = ApiLlmStatus.idle;
        debugPrint('[API-LLM] Connection test passed ✓');
        return true;
      } else {
        final decoded = jsonDecode(body);
        _errorMessage = decoded['error']?['message'] ?? 'HTTP ${response.statusCode}';
        _status = ApiLlmStatus.error;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _status = ApiLlmStatus.error;
      debugPrint('[API-LLM] Connection test failed: $e');
      return false;
    }
  }

  /// Generate a streaming chat-completion response
  Stream<String> generateStream({
    required List<Map<String, String>> messages,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.9,
  }) async* {
    if (!isConfigured) {
      yield 'Error: API not configured. Go to Settings → API to add your key.';
      return;
    }
    if (_status == ApiLlmStatus.streaming) {
      yield 'Error: Already generating a response.';
      return;
    }

    _status = ApiLlmStatus.streaming;
    _shouldStop = false;
    _errorMessage = null;

    try {
      final uri = Uri.parse('${_config!.baseUrl}/chat/completions');
      final request = await _getClient().postUrl(uri);
      request.headers.set('Authorization', 'Bearer ${_config!.apiKey}');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'text/event-stream');

      // Add extra headers for OpenRouter
      if (_config!.provider == ApiProvider.openRouter) {
        request.headers.set('HTTP-Referer', 'https://local-llm-assistant.app');
        request.headers.set('X-Title', 'Local LLM Assistant');
      }

      final body = jsonEncode({
        'model': _config!.model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'top_p': topP,
        'stream': true,
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode != 200) {
        final errBody = await response.transform(utf8.decoder).join();
        String errMsg;
        try {
          final decoded = jsonDecode(errBody);
          errMsg = decoded['error']?['message'] ?? 'HTTP ${response.statusCode}';
        } catch (_) {
          errMsg = 'HTTP ${response.statusCode}: $errBody';
        }
        _status = ApiLlmStatus.error;
        _errorMessage = errMsg;
        yield '\n\n⚠️ API Error: $errMsg';
        return;
      }

      // Parse SSE stream
      final lineStream = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (_shouldStop) break;

        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'];
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (_) {
            // Skip malformed SSE chunks
          }
        }
      }

      _status = ApiLlmStatus.idle;
      debugPrint('[API-LLM] Generation complete.');
    } catch (e) {
      _status = ApiLlmStatus.error;
      _errorMessage = e.toString();
      debugPrint('[API-LLM] Generation error: $e');
      yield '\n\n⚠️ API Error: $e';
      _status = ApiLlmStatus.idle;
    }
  }

  /// Stop current streaming generation
  void stopGeneration() {
    _shouldStop = true;
    _status = ApiLlmStatus.idle;
  }

  HttpClient _getClient() {
    _httpClient ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
    return _httpClient!;
  }

  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
