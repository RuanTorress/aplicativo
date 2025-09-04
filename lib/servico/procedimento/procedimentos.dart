import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modelo para procedimento (nome e valor)
class Procedimento {
  String nome;
  double valor;

  Procedimento({required this.nome, required this.valor});

  Map<String, dynamic> toMap() => {'nome': nome, 'valor': valor};
  factory Procedimento.fromMap(Map map) =>
      Procedimento(nome: map['nome'], valor: (map['valor'] ?? 0).toDouble());
}

class ProcedimentosScreen extends StatefulWidget {
  final Function(BuildContext, {int? index, Procedimento? procedimento})
  onAddEdit;

  const ProcedimentosScreen({super.key, required this.onAddEdit});

  @override
  _ProcedimentosScreenState createState() => _ProcedimentosScreenState();
}

class _ProcedimentosScreenState extends State<ProcedimentosScreen> {
  final Box procedimentosBox = Hive.box('procedimentos');

  void _removerProcedimento(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remover Procedimento'),
        content: Text('Tem certeza que deseja remover este procedimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              procedimentosBox.deleteAt(index);
              Navigator.pop(context);
            },
            child: Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      body: ValueListenableBuilder(
        valueListenable: procedimentosBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                'Nenhum procedimento cadastrado.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final map = box.getAt(index);
              final procedimento = map is Map
                  ? Procedimento.fromMap(map)
                  : Procedimento(nome: map.toString(), valor: 0);
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.medical_services, color: Colors.white),
                  ),
                  title: Text(
                    procedimento.nome,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Valor: R\$ ${procedimento.valor.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => widget.onAddEdit(
                          context,
                          index: index,
                          procedimento: procedimento,
                        ),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerProcedimento(context, index),
                        tooltip: 'Remover',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
