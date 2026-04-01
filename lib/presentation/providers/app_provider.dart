import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/model_info.dart';
import '../../data/services/llm_service.dart';
import '../../data/services/model_service.dart';
import '../../core/constants/app_constants.dart';

class AppProvider extends ChangeNotifier {
  final LlmService _llmService = LlmService();
  final ModelService _modelService = ModelService();

  // State
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<ModelInfo> _models = [];
  ModelInfo? _selectedModel;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  String _streamingResponse = '';

  // Settings
  String _systemPrompt = AppConstants.defaultSystemPrompt;
  int _maxTokens = AppConstants.defaultMaxTokens;
  double _temperature = AppConstants.defaultTemperature;
  double _topP = AppConstants.defaultTopP;
  double _repeatPenalty = AppConstants.defaultRepeatPenalty;
  int _contextLength = AppConstants.defaultContextLength;
  int _nGpuLayers = AppConstants.defaultNGpuLayers;
  int _nThreads = AppConstants.defaultNThreads;
  String _selectedTemplate = 'ChatML';

  // Getters
  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  List<ModelInfo> get models => _models;
  ModelInfo? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String get streamingResponse => _streamingResponse;
  LlmStatus get llmStatus => _llmService.status;
  bool get isModelLoaded => _llmService.isModelLoaded;

  String get systemPrompt => _systemPrompt;
  int get maxTokens => _maxTokens;
  double get temperature => _temperature;
  double get topP => _topP;
  double get repeatPenalty => _repeatPenalty;
  int get contextLength => _contextLength;
  int get nGpuLayers => _nGpuLayers;
  int get nThreads => _nThreads;
  String get selectedTemplate => _selectedTemplate;

  Future<void> init() async {
    await _modelService.init();
    await _loadSettings();
    _loadModels();
    _loadSessions();
    notifyListeners();
  }

  // ── Model Management ──────────────────────────────────────────────────────

  void _loadModels() {
    _models = _modelService.getModels();
  }

  Future<void> addModel() async {
    _setLoading(true);
    try {
      final model = await _modelService.pickAndAddModel();
      if (model != null) {
        _models = _modelService.getModels();
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add model: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadModel(ModelInfo model) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final success = await _llmService.loadModel(model);
      if (success) {
        _selectedModel = model;
        _selectedTemplate = model.templateName;
        await _saveSettings();
        _clearError();
      } else {
        _setError(_llmService.errorMessage ?? 'Failed to load model');
      }
      return success;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> deleteModel(String id) async {
    await _modelService.deleteModel(id);
    if (_selectedModel?.id == id) {
      _selectedModel = null;
    }
    _models = _modelService.getModels();
    notifyListeners();
  }

  // ── Chat Sessions ─────────────────────────────────────────────────────────

  void _loadSessions() {
    final box = Hive.box<ChatSession>(AppConstants.chatBoxName);
    _sessions = box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> createNewSession() async {
    final session = ChatSession(modelName: _selectedModel?.name);
    final box = Hive.box<ChatSession>(AppConstants.chatBoxName);
    await box.put(session.id, session);
    _sessions.insert(0, session);
    _currentSession = session;
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    _currentSession = session;
    _streamingResponse = '';
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    final box = Hive.box<ChatSession>(AppConstants.chatBoxName);
    await box.delete(id);
    _sessions.removeWhere((s) => s.id == id);
    if (_currentSession?.id == id) {
      _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
    }
    notifyListeners();
  }

  // ── Inference ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!_llmService.isModelLoaded) {
      _setError('Please load a model first!');
      return;
    }
    if (_isGenerating) return;

    // Ensure we have a session
    if (_currentSession == null) {
      await createNewSession();
    }

    final userMessage = ChatMessage(
      content: text.trim(),
      role: MessageRole.user,
    );

    _currentSession!.addMessage(userMessage);
    _saveCurrentSession();

    _isGenerating = true;
    _streamingResponse = '';
    _clearError();
    notifyListeners();

    // Build prompt
    final prompt = _llmService.buildPrompt(
      userMessage: text.trim(),
      systemPrompt: _systemPrompt,
      templateName: _selectedTemplate,
    );

    final buffer = StringBuffer();
    final stopwatch = Stopwatch()..start();

    try {
      await for (final token in _llmService.generateStream(
        prompt: prompt,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topP: _topP,
        repeatPenalty: _repeatPenalty,
      )) {
        buffer.write(token);
        _streamingResponse = buffer.toString();
        notifyListeners();
      }
    } finally {
      stopwatch.stop();
      _isGenerating = false;

      final aiMessage = ChatMessage(
        content: buffer.toString().trim(),
        role: MessageRole.assistant,
        inferenceTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );

      _currentSession!.addMessage(aiMessage);
      _streamingResponse = '';
      _saveCurrentSession();
      notifyListeners();
    }
  }

  Future<void> stopGeneration() async {
    await _llmService.stopGeneration();
    _isGenerating = false;
    notifyListeners();
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) return;
    final box = Hive.box<ChatSession>(AppConstants.chatBoxName);
    await box.put(_currentSession!.id, _currentSession!);
    _sessions = box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _systemPrompt = prefs.getString(AppConstants.keySystemPrompt) ??
        AppConstants.defaultSystemPrompt;
    _maxTokens = prefs.getInt(AppConstants.keyMaxTokens) ??
        AppConstants.defaultMaxTokens;
    _temperature = prefs.getDouble(AppConstants.keyTemperature) ??
        AppConstants.defaultTemperature;
    _topP = prefs.getDouble(AppConstants.keyTopP) ?? AppConstants.defaultTopP;
    _repeatPenalty = prefs.getDouble(AppConstants.keyRepeatPenalty) ??
        AppConstants.defaultRepeatPenalty;
    _contextLength = prefs.getInt(AppConstants.keyContextLength) ??
        AppConstants.defaultContextLength;
    _nGpuLayers = prefs.getInt(AppConstants.keyNGpuLayers) ??
        AppConstants.defaultNGpuLayers;
    _nThreads = prefs.getInt(AppConstants.keyNThreads) ??
        AppConstants.defaultNThreads;
    _selectedTemplate = prefs.getString(AppConstants.keySelectedTemplate) ??
        'ChatML';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySystemPrompt, _systemPrompt);
    await prefs.setInt(AppConstants.keyMaxTokens, _maxTokens);
    await prefs.setDouble(AppConstants.keyTemperature, _temperature);
    await prefs.setDouble(AppConstants.keyTopP, _topP);
    await prefs.setDouble(AppConstants.keyRepeatPenalty, _repeatPenalty);
    await prefs.setInt(AppConstants.keyContextLength, _contextLength);
    await prefs.setInt(AppConstants.keyNGpuLayers, _nGpuLayers);
    await prefs.setInt(AppConstants.keyNThreads, _nThreads);
    await prefs.setString(AppConstants.keySelectedTemplate, _selectedTemplate);
  }

  Future<void> updateSettings({
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? repeatPenalty,
    int? contextLength,
    int? nGpuLayers,
    int? nThreads,
    String? selectedTemplate,
  }) async {
    if (systemPrompt != null) _systemPrompt = systemPrompt;
    if (maxTokens != null) _maxTokens = maxTokens;
    if (temperature != null) _temperature = temperature;
    if (topP != null) _topP = topP;
    if (repeatPenalty != null) _repeatPenalty = repeatPenalty;
    if (contextLength != null) _contextLength = contextLength;
    if (nGpuLayers != null) _nGpuLayers = nGpuLayers;
    if (nThreads != null) _nThreads = nThreads;
    if (selectedTemplate != null) _selectedTemplate = selectedTemplate;
    await _saveSettings();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  Future<void> dispose() async {
    await _llmService.dispose();
    super.dispose();
  }
}
