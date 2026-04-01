// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModelInfoAdapter extends TypeAdapter<ModelInfo> {
  @override
  final int typeId = 3;

  @override
  ModelInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModelInfo(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      templateName: fields[3] as String,
      fileSizeBytes: fields[4] as int,
      addedAt: fields[5] as DateTime,
      isLoaded: fields[6] as bool,
      contextLength: fields[7] as int,
      nGpuLayers: fields[8] as int,
      nThreads: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ModelInfo obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.templateName)
      ..writeByte(4)
      ..write(obj.fileSizeBytes)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.isLoaded)
      ..writeByte(7)
      ..write(obj.contextLength)
      ..writeByte(8)
      ..write(obj.nGpuLayers)
      ..writeByte(9)
      ..write(obj.nThreads);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
