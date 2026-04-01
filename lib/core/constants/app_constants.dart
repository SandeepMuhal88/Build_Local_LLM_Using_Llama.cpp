class AppConstants {
  // Hive box names
  static const String chatBoxName = 'chat_sessions';
  static const String settingsBoxName = 'settings';
  static const String modelBoxName = 'models';

  // Settings keys
  static const String keySelectedModel = 'selected_model';
  static const String keySelectedTemplate = 'selected_template';
  static const String keySystemPrompt = 'system_prompt';
  static const String keyMaxTokens = 'max_tokens';
  static const String keyTemperature = 'temperature';
  static const String keyTopP = 'top_p';
  static const String keyRepeatPenalty = 'repeat_penalty';
  static const String keyContextLength = 'context_length';
  static const String keyNGpuLayers = 'n_gpu_layers';
  static const String keyNThreads = 'n_threads';

  // Default values
  static const int defaultMaxTokens = 512;
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;
  static const double defaultRepeatPenalty = 1.1;
  static const int defaultContextLength = 2048;
  static const int defaultNGpuLayers = 0; // CPU only safe default
  static const int defaultNThreads = 4;

  static const String defaultSystemPrompt =
      'You are a helpful, intelligent, and concise AI assistant running fully offline '
      'on this device. Answer questions accurately. If you do not know something, say so honestly.';

  // Prompt templates per model family
  static const Map<String, String> promptTemplates = {
    'Llama 3': llama3Template,
    'ChatML': chatmlTemplate,
    'Alpaca': alpacaTemplate,
    'Mistral': mistralTemplate,
    'Raw': rawTemplate,
  };

  static const String llama3Template =
      '<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n'
      '{system}<|eot_id|><|start_header_id|>user<|end_header_id|>\n'
      '{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n';

  static const String chatmlTemplate =
      '<|im_start|>system\n{system}<|im_end|>\n'
      '<|im_start|>user\n{user}<|im_end|>\n'
      '<|im_start|>assistant\n';

  static const String alpacaTemplate =
      '### System:\n{system}\n\n### Instruction:\n{user}\n\n### Response:\n';

  static const String mistralTemplate = '[INST] {system}\n\n{user} [/INST]';

  static const String rawTemplate = '{system}\n\nUser: {user}\nAssistant:';

  // Recommended models for mobile
  static const List<Map<String, String>> recommendedModels = [
    {
      'name': 'Llama 3.2 1B (Tiny - 800MB)',
      'filename': 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      'template': 'Llama 3',
      'url': 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF',
      'ram': '800MB',
      'quality': 'Basic',
    },
    {
      'name': 'Phi-3 Mini 3.8B (Recommended - 2.2GB)',
      'filename': 'Phi-3-mini-4k-instruct-q4.gguf',
      'template': 'ChatML',
      'url': 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf',
      'ram': '2.2GB',
      'quality': 'Good',
    },
    {
      'name': 'Gemma 2 2B (2.5GB)',
      'filename': 'gemma-2-2b-it-Q4_K_M.gguf',
      'template': 'ChatML',
      'url': 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF',
      'ram': '2.5GB',
      'quality': 'Good',
    },
    {
      'name': 'Mistral 7B (High Quality - 4.1GB)',
      'filename': 'mistral-7b-instruct-v0.2.Q4_K_M.gguf',
      'template': 'Mistral',
      'url': 'https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF',
      'ram': '4.1GB',
      'quality': 'Excellent',
    },
  ];
}
