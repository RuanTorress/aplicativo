import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../lancamento/lancamento.dart';

class CaixaPage extends StatefulWidget {
  @override
  _CaixaPageState createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage>
    with SingleTickerProviderStateMixin {
  final box = Hive.box('caixaBanco');
  List<Map<String, dynamic>> _lancamentos = [];
  double _saldoTotal = 0;
  double _metaMensal = 0;
  String _periodoAtual = 'Mensal'; // Padrão: Mensal
  TextEditingController _metaController = TextEditingController();
  late TabController _tabController;

  final List<String> _periodos = ['Diário', 'Semanal', 'Mensal'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _periodoAtual = _periodos[_tabController.index];
        });
        _refreshLancamentos();
      }
    });
    _carregarMeta();
    _refreshLancamentos();
  }

  @override
  void dispose() {
    _metaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _carregarMeta() {
    _metaMensal = box.get('metaMensal', defaultValue: 0.0);
    _metaController.text = _metaMensal.toStringAsFixed(2);
  }

  void _salvarMeta() {
    if (_metaController.text.isEmpty) return;

    try {
      final meta = double.parse(_metaController.text);
      box.put('metaMensal', meta);
      setState(() {
        _metaMensal = meta;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Meta salva com sucesso!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Valor inválido para meta"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _refreshLancamentos() {
    final now = DateTime.now();
    final data = box.keys.where((key) => key != 'metaMensal').map((key) {
      final value = box.get(key);
      return {"key": key, "value": value};
    }).toList();

    // Filtra os lançamentos de acordo com o período selecionado
    List<Map<String, dynamic>> lancamentosFiltrados = [];

    for (var lancamento in data) {
      DateTime dataLancamento = DateTime.parse(lancamento['value']['data']);
      bool incluir = false;

      switch (_periodoAtual) {
        case 'Diário':
          incluir =
              DateFormat('yyyy-MM-dd').format(dataLancamento) ==
              DateFormat('yyyy-MM-dd').format(now);
          break;
        case 'Semanal':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          incluir =
              dataLancamento.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              dataLancamento.isBefore(endOfWeek.add(const Duration(days: 1)));
          break;
        case 'Mensal':
          incluir =
              dataLancamento.month == now.month &&
              dataLancamento.year == now.year;
          break;
      }

      if (incluir) {
        lancamentosFiltrados.add(lancamento);
      }
    }

    // Calcula o saldo total
    double saldo = 0;
    for (var lancamento in lancamentosFiltrados) {
      saldo += double.parse(lancamento['value']['valor'].toString());
    }

    setState(() {
      _lancamentos = lancamentosFiltrados.reversed.toList();
      _saldoTotal = saldo;
    });
  }

  Future<void> _deletarLancamento(String key) async {
    await box.delete(key);
    _refreshLancamentos();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Lançamento deletado!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Definir cores mais profissionais
    final primaryColor = isDarkMode ? Colors.tealAccent[700] : Colors.teal[700];
    final backgroundColor = isDarkMode ? Color(0xFF1E1E28) : Colors.grey[50];
    final cardColor = isDarkMode ? Color(0xFF2D2D3A) : Colors.white;
    final positiveColor = isDarkMode
        ? Colors.greenAccent[400]
        : Colors.green[700];
    final negativeColor = isDarkMode ? Colors.redAccent[400] : Colors.red[700];

    // Formatador de moeda
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: backgroundColor,

      body: RefreshIndicator(
        onRefresh: () async {
          _refreshLancamentos();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cartão do resumo financeiro
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [Color(0xFF134E5E), Color(0xFF71B280)]
                        : [Color(0xFF00796B), Color(0xFF26A69A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Elementos decorativos
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // Conteúdo
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo $_periodoAtual',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    _saldoTotal >= 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: _saldoTotal >= 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _saldoTotal >= 0 ? "Positivo" : "Negativo",
                                    style: TextStyle(
                                      color: _saldoTotal >= 0
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            currencyFormat.format(_saldoTotal),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          Spacer(),
                          if (_metaMensal > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Meta Mensal:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(_metaMensal),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _metaMensal > 0
                                            ? (_saldoTotal / _metaMensal).clamp(
                                                0.0,
                                                1.0,
                                              )
                                            : 0,
                                        minHeight: 10,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _saldoTotal >= _metaMensal
                                                  ? Colors.greenAccent
                                                  : Colors.white,
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: -4,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _saldoTotal >= _metaMensal
                                              ? Colors.greenAccent
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${(_saldoTotal / _metaMensal * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: _saldoTotal >= _metaMensal
                                                ? Colors.black
                                                : Colors.teal[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Seção da meta mensal
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Definir Meta Mensal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _metaController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Valor da Meta R\$',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _salvarMeta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              child: Text('Salvar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Seção de lançamentos
              Container(
                width: double.infinity,
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: primaryColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Lançamentos $_periodoAtual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_lancamentos.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Lista de lançamentos
              _lancamentos.isEmpty
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 60,
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum lançamento encontrado',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _lancamentos.length,
                      itemBuilder: (_, index) {
                        final lancamento = _lancamentos[index]['value'];
                        final key = _lancamentos[index]['key'];
                        final isPositivo =
                            double.parse(lancamento['valor'].toString()) >= 0;
                        final valor = double.parse(
                          lancamento['valor'].toString(),
                        );
                        final data = DateTime.parse(lancamento['data']);

                        return Dismissible(
                          key: Key(key),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            _deletarLancamento(key);
                          },
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirmar exclusão'),
                                  content: Text(
                                    'Tem certeza que deseja excluir este lançamento?',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text('Excluir'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Card(
                            elevation: 0,
                            color: cardColor,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isPositivo
                                              ? positiveColor!.withOpacity(0.1)
                                              : negativeColor!.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getFormaPagamentoIcon(
                                            lancamento['formaPagamento'],
                                          ),
                                          color: isPositivo
                                              ? positiveColor
                                              : negativeColor,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lancamento['descricao'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  lancamento['usuario'],
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(data),
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(valor),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isPositivo
                                              ? positiveColor
                                              : negativeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (lancamento['observacao'] != null &&
                                      lancamento['observacao']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isDarkMode
                                                ? Colors.grey[800]!
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Text(
                                          '${lancamento['observacao']}',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 14,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getFormaPagamentoIcon(
                                                      lancamento['formaPagamento'],
                                                    ),
                                                    size: 14,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    lancamento['formaPagamento'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(data),
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              // Espaço adicional no final para evitar que o FAB sobreponha conteúdo
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LancamentoPage()),
          );
          if (result == true) {
            _refreshLancamentos();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Novo Lançamento'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}
