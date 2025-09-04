import 'package:hive/hive.dart';

part 'nota_model.g.dart';

@HiveType(typeId: 1)
class Nota extends HiveObject {
  @HiveField(0)
  String titulo;

  @HiveField(1)
  String status;

  @HiveField(2)
  DateTime dataHora;

  @HiveField(3)
  String observacao;

  Nota({
    required this.titulo,
    required this.status,
    required this.dataHora,
    this.observacao = '',
  });
}
