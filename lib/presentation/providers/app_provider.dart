import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/model_info.dart';
import '../../data/services/llm_service.dart';
import '../../data/services/model_service.dart';
import '../../data/services/api_llm_service.dart';
import '../../core/constants/app_constants.dart';

/// Backend mode for the LLM engine
enum LlmBackend { local, api }

class AppProvider extends ChangeNotifier {
  final LlmService _llmService = LlmService();
  final ModelService _modelService = ModelService();
  final ApiLlmService _apiService = ApiLlmService();

  // State
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<ModelInfo> _models = [];
  ModelInfo? _selectedModel;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  String _streamingResponse = '';

  // Backend mode
  LlmBackend _backend = LlmBackend.local;

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

  // API settings
  String _apiProvider = ApiProvider.openAI.name;
  String _apiKey = '';
  String _apiBaseUrl = ApiProvider.openAI.defaultBaseUrl;
  String _apiModel = 'gpt-4o-mini';

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
  bool get isModelLoaded => _backend == LlmBackend.local
      ? _llmService.isModelLoaded
      : _apiService.isConfigured;

  LlmBackend get backend => _backend;
  ApiLlmService get apiService => _apiService;

  String get systemPrompt => _systemPrompt;
  int get maxTokens => _maxTokens;
  double get temperature => _temperature;
  double get topP => _topP;
  double get repeatPenalty => _repeatPenalty;
  int get contextLength => _contextLength;
  int get nGpuLayers => _nGpuLayers;
  int get nThreads => _nThreads;
  String get selectedTemplate => _selectedTemplate;

  // API getters
  String get apiProviderName => _apiProvider;
  String get apiKey => _apiKey;
  String get apiBaseUrl => _apiBaseUrl;
  String get apiModel => _apiModel;
  ApiProvider get currentApiProvider => ApiProvider.values.firstWhere(
        (p) => p.name == _apiProvider,
        orElse: () => ApiProvider.openAI,
      );
  bool get isApiConfigured => _apiService.isConfigured;

  /// The display name for the active backend
  String get activeBackendName {
    if (_backend == LlmBackend.local) {
      return _selectedModel?.name ?? 'Local (no model)';
    } else {
      return '${currentApiProvider.label}: $_apiModel';
    }
  }

  Future<void> init() async {
    await _modelService.init();
    await _loadSettings();
    _loadModels();
    _loadSessions();

    // Restore API config if saved
    if (_apiKey.isNotEmpty) {
      _apiService.configure(ApiConfig(
        provider: currentApiProvider,
        apiKey: _apiKey,
        baseUrl: _apiBaseUrl,
        model: _apiModel,
      ));
    }

    notifyListeners();
  }

  // ── Backend Switching ──────────────────────────────────────────────────────

  Future<void> setBackend(LlmBackend newBackend) async {
    _backend = newBackend;
    _clearError();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_backend', newBackend.name);
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
        _backend = LlmBackend.local;
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

  // ── API Configuration ─────────────────────────────────────────────────────

  Future<void> configureApi({
    required ApiProvider provider,
    required String apiKey,
    String? baseUrl,
    required String model,
  }) async {
    _apiProvider = provider.name;
    _apiKey = apiKey;
    _apiBaseUrl = baseUrl ?? provider.defaultBaseUrl;
    _apiModel = model;

    final config = ApiConfig(
      provider: provider,
      apiKey: apiKey,
      baseUrl: _apiBaseUrl,
      model: model,
    );
    _apiService.configure(config);
    _backend = LlmBackend.api;
    _clearError();

    await _saveSettings();
    notifyListeners();
  }

  Future<bool> testApiConnection() async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final success = await _apiService.testConnection();
      if (!success) {
        _setError(_apiService.errorMessage ?? 'Connection failed');
      }
      return success;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ── Chat Sessions ─────────────────────────────────────────────────────────

  void _loadSessions() {
    final box = Hive.box<ChatSession>(AppConstants.chatBoxName);
    _sessions = box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> createNewSession() async {
    final modelName = _backend == LlmBackend.local
        ? _selectedModel?.name
        : '$_apiModel (API)';
    final session = ChatSession(modelName: modelName);
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

    if (_backend == LlmBackend.local && !_llmService.isModelLoaded) {
      _setError('Please load a model first!');
      return;
    }
    if (_backend == LlmBackend.api && !_apiService.isConfigured) {
      _setError('Please configure your API key first!');
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

    final buffer = StringBuffer();
    final stopwatch = Stopwatch()..start();

    try {
      if (_backend == LlmBackend.local) {
        await _generateLocal(text, buffer);
      } else {
        await _generateApi(text, buffer);
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

  Future<void> _generateLocal(String text, StringBuffer buffer) async {
    final prompt = _llmService.buildPrompt(
      userMessage: text.trim(),
      systemPrompt: _systemPrompt,
      templateName: _selectedTemplate,
    );

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
  }

  Future<void> _generateApi(String text, StringBuffer buffer) async {
    // Build conversation messages with context
    final messages = <Map<String, String>>[];

    // System message
    messages.add({
      'role': 'system',
      'content': _systemPrompt,
    });

    // Include conversation history (last N messages for context)
    final history = _currentSession?.messages ?? [];
    const maxHistoryMessages = 20;
    final startIdx = history.length > maxHistoryMessages
        ? history.length - maxHistoryMessages
        : 0;

    for (int i = startIdx; i < history.length; i++) {
      final msg = history[i];
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    await for (final token in _apiService.generateStream(
      messages: messages,
      maxTokens: _maxTokens,
      temperature: _temperature,
      topP: _topP,
    )) {
      buffer.write(token);
      _streamingResponse = buffer.toString();
      notifyListeners();
    }
  }

  Future<void> stopGeneration() async {
    if (_backend == LlmBackend.local) {
      await _llmService.stopGeneration();
    } else {
      _apiService.stopGeneration();
    }
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

    // Load API settings
    _apiProvider = prefs.getString('api_provider') ?? ApiProvider.openAI.name;
    _apiKey = prefs.getString('api_key') ?? '';
    _apiBaseUrl = prefs.getString('api_base_url') ?? ApiProvider.openAI.defaultBaseUrl;
    _apiModel = prefs.getString('api_model') ?? 'gpt-4o-mini';

    // Load backend mode
    final backendStr = prefs.getString('llm_backend') ?? 'local';
    _backend = LlmBackend.values.firstWhere(
      (b) => b.name == backendStr,
      orElse: () => LlmBackend.local,
    );
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

    // Save API settings
    await prefs.setString('api_provider', _apiProvider);
    await prefs.setString('api_key', _apiKey);
    await prefs.setString('api_base_url', _apiBaseUrl);
    await prefs.setString('api_model', _apiModel);
    await prefs.setString('llm_backend', _backend.name);
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
    _apiService.dispose();
    super.dispose();
  }
}
