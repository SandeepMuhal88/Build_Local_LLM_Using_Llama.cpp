import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_llama/flutter_llama.dart';
import '../models/model_info.dart';
import '../../core/constants/app_constants.dart';

enum LlmStatus { idle, loading, generating, error, disposed }

class LlmService {
  final _llama = FlutterLlama.instance;
  LlmStatus _status = LlmStatus.idle;
  String? _errorMessage;
  ModelInfo? _loadedModel;

  LlmStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ModelInfo? get loadedModel => _loadedModel;
  bool get isModelLoaded =>
      _loadedModel != null && _status != LlmStatus.error;
  bool get isGenerating => _status == LlmStatus.generating;

  /// Load a GGUF model from [model.filePath]
  Future<bool> loadModel(ModelInfo model) async {
    try {
      _status = LlmStatus.loading;
      _errorMessage = null;

      // Unload any previous model
      try {
        await _llama.unloadModel();
      } catch (_) {}

      final file = File(model.filePath);
      if (!await file.exists()) {
        throw Exception('Model file not found: ${model.filePath}');
      }

      debugPrint('[LLM] Loading model: ${model.name} (${model.sizeString})');

      final config = LlamaConfig(
        modelPath: model.filePath,
        nThreads: model.nThreads,
        nGpuLayers: model.nGpuLayers, // 0 = CPU, -1 = all on GPU
        contextSize: model.contextLength,
        batchSize: 512,
        useGpu: model.nGpuLayers != 0,
        verbose: kDebugMode,
      );

      final success = await _llama.loadModel(config);

      if (success) {
        _loadedModel = model;
        _status = LlmStatus.idle;
        debugPrint('[LLM] Model loaded successfully!');
        return true;
      } else {
        throw Exception('loadModel returned false');
      }
    } catch (e) {
      _status = LlmStatus.error;
      _errorMessage = e.toString();
      debugPrint('[LLM] Error loading model: $e');
      _loadedModel = null;
      return false;
    }
  }

  /// Generate a response with streaming, yields tokens one by one
  Stream<String> generateStream({
    required String prompt,
    int maxTokens = AppConstants.defaultMaxTokens,
    double temperature = AppConstants.defaultTemperature,
    double topP = AppConstants.defaultTopP,
    double repeatPenalty = AppConstants.defaultRepeatPenalty,
  }) async* {
    if (!isModelLoaded) {
      yield 'Error: No model loaded. Please load a GGUF model first.';
      return;
    }
    if (_status == LlmStatus.generating) {
      yield 'Error: Already generating a response.';
      return;
    }

    _status = LlmStatus.generating;

    try {
      final params = GenerationParams(
        prompt: prompt,
        temperature: temperature,
        topP: topP,
        topK: 40,
        maxTokens: maxTokens,
        repeatPenalty: repeatPenalty,
      );

      debugPrint('[LLM] Generating... (maxTokens=$maxTokens, temp=$temperature)');

      await for (final token in _llama.generateStream(params)) {
        yield token;
      }

      _status = LlmStatus.idle;
      debugPrint('[LLM] Generation complete.');
    } catch (e) {
      _status = LlmStatus.error;
      _errorMessage = e.toString();
      debugPrint('[LLM] Generation error: $e');
      yield '\n\n⚠️ Generation error: $e';
      _status = LlmStatus.idle; // recover
    }
  }

  /// Stop current generation
  Future<void> stopGeneration() async {
    try {
      // flutter_llama doesn't expose a cancel method directly;
      // we mark idle so next check prevents continuation
      _status = LlmStatus.idle;
    } catch (e) {
      debugPrint('[LLM] Stop error: $e');
    }
  }

  /// Build the full prompt string from template
  String buildPrompt({
    required String userMessage,
    required String systemPrompt,
    required String templateName,
  }) {
    final template =
        AppConstants.promptTemplates[templateName] ?? AppConstants.rawTemplate;
    return template
        .replaceAll('{system}', systemPrompt)
        .replaceAll('{user}', userMessage);
  }

  Future<void> dispose() async {
    _status = LlmStatus.disposed;
    try {
      await _llama.unloadModel();
    } catch (_) {}
  }
}
