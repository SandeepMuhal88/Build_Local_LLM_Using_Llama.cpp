import 'package:hive/hive.dart';

part 'model_info.g.dart';

@HiveType(typeId: 3)
class ModelInfo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  String templateName;

  @HiveField(4)
  final int fileSizeBytes;

  @HiveField(5)
  final DateTime addedAt;

  @HiveField(6)
  bool isLoaded;

  @HiveField(7)
  int contextLength;

  @HiveField(8)
  int nGpuLayers;

  @HiveField(9)
  int nThreads;

  ModelInfo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.templateName,
    required this.fileSizeBytes,
    DateTime? addedAt,
    this.isLoaded = false,
    this.contextLength = 2048,
    this.nGpuLayers = 0,
    this.nThreads = 4,
  }) : addedAt = addedAt ?? DateTime.now();

  String get sizeString {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
