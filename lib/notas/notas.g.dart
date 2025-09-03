// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notas.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotaAdapter extends TypeAdapter<Nota> {
  @override
  final int typeId = 1;

  @override
  Nota read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Nota(
      titulo: fields[0] as String,
      status: fields[1] as String,
      dataHora: fields[2] as DateTime,
      observacao: fields.containsKey(3) ? fields[3] as String : '',
    );
  }

  @override
  void write(BinaryWriter writer, Nota obj) {
    writer
      ..writeByte(4) // Updated to 4 fields
      ..writeByte(0)
      ..write(obj.titulo)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.dataHora)
      ..writeByte(3)
      ..write(obj.observacao);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
