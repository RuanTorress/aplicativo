import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NovoItemDialog extends StatefulWidget {
  final TextEditingController nomeController;
  final TextEditingController quantidadeController;
  final TextEditingController valorController;
  final DateTime data;
  final void Function(DateTime) onDataChanged;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;
  final bool isEdit;

  const NovoItemDialog({
    Key? key,
    required this.nomeController,
    required this.quantidadeController,
    required this.valorController,
    required this.data,
    required this.onDataChanged,
    required this.formKey,
    required this.onSalvar,
    required this.onCancelar,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<NovoItemDialog> createState() => _NovoItemDialogState();
}

class _NovoItemDialogState extends State<NovoItemDialog> {
  late DateTime data;

  @override
  void initState() {
    super.initState();
    data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(widget.isEdit ? Icons.edit : Icons.add_box, color: Colors.blue),
          SizedBox(width: 10),
          Text(
            widget.isEdit ? 'Editar Item' : 'Adicionar Item',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto',
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Por favor, insira o nome do produto'
                    : null,
              ),
              SizedBox(height: 16),
              isSmallScreen
                  ? Column(
                      children: [
                        _buildFormField(
                          controller: widget.quantidadeController,
                          label: 'Quantidade',
                          icon: Icons.add_shopping_cart,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Insira a quantidade';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Apenas números';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        _buildFormField(
                          controller: widget.valorController,
                          label: 'Valor R\$',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Insira o valor';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: widget.quantidadeController,
                            label: 'Quantidade',
                            icon: Icons.add_shopping_cart,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insira a quantidade';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Apenas números';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildFormField(
                            controller: widget.valorController,
                            label: 'Valor R\$',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insira o valor';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data do Item:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(data),
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: () async {
                            DateTime? novaData = await showDatePicker(
                              context: context,
                              initialDate: data,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blue,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (novaData != null) {
                              setState(() {
                                data = novaData;
                              });
                              widget.onDataChanged(novaData);
                            }
                          },
                          icon: Icon(Icons.edit_calendar),
                          label: Text('Alterar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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
          label: Text('Cancelar'),
          onPressed: widget.onCancelar,
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text('Salvar'),
          onPressed: widget.onSalvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
