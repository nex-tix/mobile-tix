// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedScanAdapter extends TypeAdapter<QueuedScan> {
  @override
  final int typeId = 0;

  @override
  QueuedScan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedScan(
      id: fields[0] as String,
      ticketCode: fields[1] as String,
      mode: fields[2] as String,
      checkpointId: fields[3] as String,
      queuedAt: fields[4] as DateTime,
      retryCount: fields[5] as int,
      actualVisitorCount: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedScan obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ticketCode)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.checkpointId)
      ..writeByte(4)
      ..write(obj.queuedAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.actualVisitorCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
