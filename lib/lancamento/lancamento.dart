import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Helpers de formatação
  final NumberFormat _brlFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );
  bool _isFormattingValor = false;

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    // Formatar valor enquanto digita em padrão BR (ex: 1.234,56)
    _valorController.addListener(_onValorChanged);
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.removeListener(_onValorChanged);
    _valorController.dispose();
    _usuarioController.dispose();
    _observacaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  void _onValorChanged() {
    if (_isFormattingValor) return;
    final raw = _valorController.text;
    if (raw.isEmpty) return;

    // Mantém apenas dígitos
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return;
    }

    // Converte para centavos e formata
    _isFormattingValor = true;
    try {
      final valueInCents = int.parse(digits);
      final value = valueInCents / 100.0;
      final formatted = _brlFormatter.format(value).trim();
      final selectionIndexFromEnd =
          _valorController.text.length - _valorController.selection.end;
      _valorController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: (formatted.length - selectionIndexFromEnd).clamp(
            0,
            formatted.length,
          ),
        ),
      );
    } catch (_) {
      // Se algo der errado, não quebra a digitação
    } finally {
      _isFormattingValor = false;
    }
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
      // Converte "1.234,56" -> "1234.56"
      final sanitized = _valorController.text
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      double valor = double.parse(sanitized);

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
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode
            ? Colors.white
            : theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seção: Tipo de Lançamento (Entrada/Saída)
                _buildSection(
                  context,
                  title: 'Tipo de Lançamento',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypePill(
                          context,
                          label: 'Entrada',
                          selected: _isEntrada,
                          selectedColor: Colors.green,
                          onTap: () => setState(() => _isEntrada = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypePill(
                          context,
                          label: 'Saída',
                          selected: !_isEntrada,
                          selectedColor: Colors.red,
                          onTap: () => setState(() => _isEntrada = false),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Seção: Informações principais
                _buildSection(
                  context,
                  title: 'Informações',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descricaoController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          hintText: 'Ex.: Venda de produto',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description_outlined),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant
                              .withOpacity(0.4),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe a descrição';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Valor',
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant
                              .withOpacity(0.4),
                          helperText: 'Use vírgula para centavos. Ex.: 123,45',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe o valor';
                          }
                          final sanitized = value
                              .replaceAll('.', '')
                              .replaceAll(',', '.');
                          final parsed = double.tryParse(sanitized);
                          if (parsed == null) return 'Valor inválido';
                          if (parsed <= 0)
                            return 'Informe um valor maior que zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
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
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.edit_calendar_outlined),
                                onPressed: () => _selectDate(context),
                                tooltip: 'Selecionar data',
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.4),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usuarioController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nome do Usuário',
                          hintText: 'Quem realizou o lançamento?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant
                              .withOpacity(0.4),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe o nome do usuário';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Seção: Pagamento
                _buildSection(
                  context,
                  title: 'Forma de Pagamento',
                  child: DropdownButtonFormField<String>(
                    value: _formaPagamento,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                        0.4,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Dinheiro',
                        child: Text('Dinheiro'),
                      ),
                      DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                      DropdownMenuItem(
                        value: 'Cartão de Crédito',
                        child: Text('Cartão de Crédito'),
                      ),
                      DropdownMenuItem(
                        value: 'Cartão de Débito',
                        child: Text('Cartão de Débito'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _formaPagamento = v ?? 'Dinheiro'),
                  ),
                ),

                const SizedBox(height: 12),

                // Seção: Observação
                _buildSection(
                  context,
                  title: 'Observação',
                  child: TextFormField(
                    controller: _observacaoController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Observação (opcional)',
                      hintText: 'Adicione detalhes relevantes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_outlined),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                        0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Botão fixo inferior para melhor UX móvel
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _salvarLancamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEntrada
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _isEntrada ? 'Registrar Entrada' : 'Registrar Saída',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper de seção com título e conteúdo
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // Botões de seleção de tipo em estilo "pill"
  Widget _buildTypePill(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bg = selected
        ? selectedColor.withOpacity(0.15)
        : theme.colorScheme.surfaceVariant.withOpacity(0.6);
    final fg = selected
        ? selectedColor
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? selectedColor.withOpacity(0.6)
                : theme.dividerColor.withOpacity(0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Entrada'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: fg,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
