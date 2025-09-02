import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class LancamentoPage extends StatefulWidget {
  const LancamentoPage({super.key});

  @override
  _LancamentoPageState createState() => _LancamentoPageState();
}

class _LancamentoPageState extends State<LancamentoPage> {
  final box = Hive.box('caixaBanco');
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controllers
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  // Valores
  String _formaPagamento = 'Dinheiro';
  bool _isEntrada = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _usuarioController.dispose();
    _observacaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _salvarLancamento() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      double valor = double.parse(_valorController.text.replaceAll(',', '.'));

      // Ajusta o valor para negativo se for saída
      if (!_isEntrada) {
        valor = -valor;
      }

      // Gera um ID único para o lançamento
      String id = _uuid.v4();

      await box.put(id, {
        'descricao': _descricaoController.text,
        'valor': valor,
        'usuario': _usuarioController.text,
        'observacao': _observacaoController.text,
        'formaPagamento': _formaPagamento,
        'data': _selectedDate.toIso8601String(),
        'tipo': _isEntrada ? 'Entrada' : 'Saída',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lançamento salvo com sucesso!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar lançamento: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lançamento'),
        elevation: 0,
        backgroundColor: isDarkMode
            ? Colors.grey[900]
            : theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de Lançamento (Entrada/Saída)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Tipo de Lançamento:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      ChoiceChip(
                        label: const Text('Entrada'),
                        selected: _isEntrada,
                        selectedColor: Colors.green[100],
                        backgroundColor: isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: _isEntrada
                              ? Colors.green[800]
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _isEntrada = true;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Saída'),
                        selected: !_isEntrada,
                        selectedColor: Colors.red[100],
                        backgroundColor: isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: !_isEntrada
                              ? Colors.red[800]
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _isEntrada = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a descrição';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Valor
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor R\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o valor';
                  }
                  try {
                    double.parse(value.replaceAll(',', '.'));
                  } catch (e) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Data
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dataController,
                    decoration: InputDecoration(
                      labelText: 'Data',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe a data';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Usuário
              TextFormField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: 'Nome do Usuário',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o nome do usuário';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Forma de pagamento
              Text(
                'Forma de Pagamento',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  _buildFormaChip('Dinheiro', Icons.money),
                  _buildFormaChip('Pix', Icons.pix),
                  _buildFormaChip('Cartão de Crédito', Icons.credit_card),
                  _buildFormaChip('Cartão de Débito', Icons.payment),
                ],
              ),

              const SizedBox(height: 20),

              // Observação
              TextFormField(
                controller: _observacaoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvarLancamento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEntrada
                        ? Colors.green[600]
                        : Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Salvar Lançamento',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormaChip(String label, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: _formaPagamento == label ? Colors.blue[800] : null,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: _formaPagamento == label,
      onSelected: (selected) {
        setState(() {
          _formaPagamento = label;
        });
      },
      selectedColor: Colors.blue[100],
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      checkmarkColor: Colors.blue[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
