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

class ProcedimentosScreen extends StatelessWidget {
  final Box procedimentosBox = Hive.box('procedimentos');

  void _adicionarOuEditarProcedimento(
    BuildContext context, {
    int? index,
    Procedimento? procedimento,
  }) {
    final TextEditingController nomeController = TextEditingController(
      text: procedimento?.nome ?? '',
    );
    final TextEditingController valorController = TextEditingController(
      text: procedimento != null ? procedimento.valor.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                index == null ? 'Novo Procedimento' : 'Editar Procedimento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do procedimento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final nome = nomeController.text.trim();
                      final valor =
                          double.tryParse(
                            valorController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      if (nome.isNotEmpty) {
                        final novoProcedimento = Procedimento(
                          nome: nome,
                          valor: valor,
                        ).toMap();
                        if (index == null) {
                          procedimentosBox.add(novoProcedimento);
                        } else {
                          procedimentosBox.putAt(index, novoProcedimento);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text(index == null ? 'Adicionar' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        onPressed: () => _adicionarOuEditarProcedimento(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _adicionarOuEditarProcedimento(context),
        icon: Icon(Icons.add),
        label: Text('Adicionar'),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
