import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/model_info.dart';
import '../../core/constants/app_constants.dart';

class ModelService {
  static const String _boxName = AppConstants.modelBoxName;

  Box<ModelInfo>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<ModelInfo>(_boxName);
  }

  List<ModelInfo> getModels() {
    return _box?.values.toList() ?? [];
  }

  ModelInfo? getModelById(String id) {
    return _box?.values.firstWhere((m) => m.id == id,
        orElse: () => throw Exception('Model not found'));
  }

  /// Pick a .gguf file and copy it to app storage
  Future<ModelInfo?> pickAndAddModel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf', 'bin'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.path == null) return null;

      final sourceFile = File(file.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory(p.join(appDir.path, 'models'));
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      // Copy to app models directory
      final destPath = p.join(modelsDir.path, file.name);
      if (!await File(destPath).exists()) {
        debugPrint('[ModelService] Copying model to: $destPath');
        await sourceFile.copy(destPath);
      }

      final fileStat = await File(destPath).stat();
      final modelName = p.basenameWithoutExtension(file.name);

      // Detect template from filename
      String template = _detectTemplate(modelName);

      final model = ModelInfo(
        id: const Uuid().v4(),
        name: modelName,
        filePath: destPath,
        templateName: template,
        fileSizeBytes: fileStat.size,
      );

      await _box?.put(model.id, model);
      debugPrint('[ModelService] Model added: ${model.name}');
      return model;
    } catch (e) {
      debugPrint('[ModelService] Error adding model: $e');
      return null;
    }
  }

  /// Add a model from a file path directly (e.g. already on device)
  Future<ModelInfo?> addModelFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('File not found: $filePath');

      final fileStat = await file.stat();
      final name = p.basenameWithoutExtension(p.basename(filePath));
      final template = _detectTemplate(name);

      final model = ModelInfo(
        id: const Uuid().v4(),
        name: name,
        filePath: filePath,
        templateName: template,
        fileSizeBytes: fileStat.size,
      );

      await _box?.put(model.id, model);
      return model;
    } catch (e) {
      debugPrint('[ModelService] Error adding model from path: $e');
      return null;
    }
  }

  Future<void> deleteModel(String id) async {
    final model = _box?.get(id);
    if (model != null) {
      // Delete file if it's in app directory
      final appDir = await getApplicationDocumentsDirectory();
      if (model.filePath.startsWith(appDir.path)) {
        final file = File(model.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _box?.delete(id);
    }
  }

  Future<void> updateModel(ModelInfo model) async {
    await _box?.put(model.id, model);
  }

  String _detectTemplate(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('llama-3') || lower.contains('llama3')) {
      return 'Llama 3';
    } else if (lower.contains('mistral') || lower.contains('mixtral')) {
      return 'Mistral';
    } else if (lower.contains('phi')) {
      return 'ChatML';
    } else if (lower.contains('gemma')) {
      return 'ChatML';
    } else if (lower.contains('alpaca') || lower.contains('vicuna')) {
      return 'Alpaca';
    } else {
      return 'ChatML';
    }
  }
}
