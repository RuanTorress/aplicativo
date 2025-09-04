import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class NovoLancamentoDialog extends StatefulWidget {
  final Box box;
  final VoidCallback onSave;
  final Map<String, dynamic>? lancamento;
  final int? lancamentoKey; // Renomeado de 'key' para 'lancamentoKey'

  const NovoLancamentoDialog({
    super.key,
    required this.box,
    required this.onSave,
    this.lancamento,
    this.lancamentoKey, // Atualizado aqui
  });

  @override
  _NovoLancamentoDialogState createState() => _NovoLancamentoDialogState();
}

class _NovoLancamentoDialogState extends State<NovoLancamentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _usuarioController = TextEditingController();
  String _formaPagamento = 'Dinheiro';
  DateTime _data = DateTime.now();

  final List<String> _formasPagamento = [
    'Dinheiro',
    'Pix',
    'Cartão de Crédito',
    'Cartão de Débito',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lancamento != null) {
      _descricaoController.text =
          widget.lancamento!['descricao']?.toString() ?? '';
      _valorController.text = widget.lancamento!['valor']?.toString() ?? '';
      _observacaoController.text =
          widget.lancamento!['observacao']?.toString() ?? '';
      _usuarioController.text = widget.lancamento!['usuario']?.toString() ?? '';
      _formaPagamento =
          widget.lancamento!['formaPagamento']?.toString() ?? 'Dinheiro';
      _data = widget.lancamento!['data'] != null
          ? DateTime.parse(widget.lancamento!['data'])
          : DateTime.now();
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _usuarioController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valor = double.tryParse(_valorController.text);
      if (valor == null) {
        // This should not happen due to validator, but just in case
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Valor inválido')));
        return;
      }

      final novoLancamento = {
        'descricao': _descricaoController.text,
        'valor': valor,
        'formaPagamento': _formaPagamento,
        'data': _data.toIso8601String(),
        'observacao': _observacaoController.text,
        'usuario': _usuarioController.text,
      };

      if (widget.lancamentoKey != null) {
        widget.box.put(
          widget.lancamentoKey!,
          novoLancamento,
        ); // Corrigido: usar put para map box
      } else {
        widget.box.add(novoLancamento);
      }

      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final backgroundColor = isDarkMode ? Color(0xFF2C2C36) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 10,
      backgroundColor: backgroundColor,
      child: Container(
        padding: EdgeInsets.all(20.0),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título aprimorado
            Row(
              children: [
                Icon(
                  widget.lancamento != null ? Icons.edit : Icons.add,
                  color: primaryColor,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  widget.lancamento != null
                      ? 'Editar Lançamento'
                      : 'Novo Lançamento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Formulário aprimorado
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo Descrição com ícone
                    TextFormField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(
                          Icons.description,
                          color: primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    SizedBox(height: 15),
                    // Campo Valor com ícone
                    TextFormField(
                      controller: _valorController,
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null)
                          return 'Valor inválido';
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    // Dropdown Forma de Pagamento
                    DropdownButtonFormField<String>(
                      value: _formaPagamento,
                      items: _formasPagamento
                          .map(
                            (forma) => DropdownMenuItem(
                              value: forma,
                              child: Row(
                                children: [
                                  Icon(
                                    _getFormaPagamentoIcon(forma),
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 10),
                                  Text(forma),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _formaPagamento = value!),
                      decoration: InputDecoration(
                        labelText: 'Forma de Pagamento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 15),
                    // Campo Observação com ícone
                    TextFormField(
                      controller: _observacaoController,
                      decoration: InputDecoration(
                        labelText: 'Observação',
                        prefixIcon: Icon(Icons.note, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 15),
                    // Campo Usuário com ícone
                    TextFormField(
                      controller: _usuarioController,
                      decoration: InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    SizedBox(height: 15),
                    // Seletor de Data aprimorado
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: isDarkMode
                            ? Color(0xFF1E1E28)
                            : Colors.grey[100],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: primaryColor),
                          SizedBox(width: 10),
                          Text(
                            'Data: ${DateFormat('dd/MM/yyyy').format(_data)}',
                            style: TextStyle(color: textColor),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.edit_calendar,
                              color: primaryColor,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _data,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => _data = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botões aprimorados
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para ícones de forma de pagamento
  IconData _getFormaPagamentoIcon(String formaPagamento) {
    switch (formaPagamento) {
      case 'Pix':
        return Icons.pix;
      case 'Dinheiro':
        return Icons.monetization_on_rounded;
      case 'Cartão de Crédito':
        return Icons.credit_card;
      case 'Cartão de Débito':
        return Icons.payment;
      default:
        return Icons.receipt_long;
    }
  }
}
