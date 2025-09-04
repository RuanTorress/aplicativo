import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'nota_model.dart';

class NotasDialogs {
  static void showAddEditDialog({
    required BuildContext context,
    required TextEditingController tituloController,
    required TextEditingController observacaoController,
    required String statusSelecionado,
    required Function(String) onStatusChanged,
    required List<String> statusOptions,
    required Map<String, Color> statusColors,
    required Box<Nota> notasBox,
    Nota? nota,
    int? index,
  }) {
    if (nota != null) {
      tituloController.text = nota.titulo;
      observacaoController.text = nota.observacao;
      onStatusChanged(nota.status);
    } else {
      tituloController.clear();
      observacaoController.clear();
      onStatusChanged("Pendente");
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 10,
        title: Row(
          children: [
            Icon(
              nota == null ? Icons.note_add : Icons.edit_note,
              color: Colors.blue.shade600,
            ),
            SizedBox(width: 10),
            Text(nota == null ? "Nova Nota" : "Editar Nota"),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: "Título",
                    hintText: "Digite o título da sua nota",
                    prefixIcon: Icon(Icons.title, color: Colors.blue.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.blue.shade500,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: observacaoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Observação",
                    hintText: "Digite detalhes adicionais aqui",
                    prefixIcon: Icon(
                      Icons.description,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.blue.shade500,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, bottom: 8),
                        child: Text(
                          "Status",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: statusSelecionado,
                        items: statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: statusColors[status],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(status),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          onStatusChanged(valor!);
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.label_important,
                            color: statusColors[statusSelecionado],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: statusColors[statusSelecionado]!,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: statusColors[statusSelecionado],
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.cancel, color: Colors.grey),
            label: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text(nota == null ? "Salvar" : "Atualizar"),
            onPressed: () {
              if (tituloController.text.isNotEmpty) {
                final novaNota = Nota(
                  titulo: tituloController.text,
                  status: statusSelecionado,
                  dataHora: DateTime.now(),
                  observacao: observacaoController.text,
                );
                if (nota == null) {
                  notasBox.add(novaNota);
                } else {
                  notasBox.putAt(index!, novaNota);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          nota == null
                              ? 'Nota adicionada com sucesso!'
                              : 'Nota atualizada com sucesso!',
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showDeleteDialog({
    required BuildContext context,
    required Box<Nota> notasBox,
    required int index,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 10),
            Text("Confirmar exclusão"),
          ],
        ),
        content: Text("Tem certeza que deseja excluir esta nota?"),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.cancel),
            label: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text("Excluir"),
            onPressed: () {
              notasBox.deleteAt(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Nota excluída com sucesso!'),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
