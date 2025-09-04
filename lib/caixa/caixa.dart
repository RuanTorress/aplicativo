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
  final box = Hive.box('caixabanco');
  List<Map<String, dynamic>> _lancamentos = [];
  double _saldoTotal = 0;
  double _metaMensal = 0;
  String _periodoAtual = 'Mensal'; // Padrão: Mensal
  TextEditingController _metaController = TextEditingController();
  late TabController _tabController;
  bool _showMetaCard =
      true; // Novo estado para controlar visibilidade do card de meta

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
      return {"key": key, "value": box.get(key)};
    }).toList();

    // Filtra os lançamentos de acordo com o período selecionado
    List<Map<String, dynamic>> lancamentosFiltrados = [];

    for (var lancamento in data) {
      final value = Map<String, dynamic>.from(lancamento['value'] as Map);
      final dataLancamento = DateTime.parse(value['data']);
      bool incluir = false;

      switch (_periodoAtual) {
        case 'Diário':
          incluir =
              dataLancamento.year == now.year &&
              dataLancamento.month == now.month &&
              dataLancamento.day == now.day;
          break;
        case 'Semanal':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));
          incluir =
              dataLancamento.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              dataLancamento.isBefore(endOfWeek.add(Duration(days: 1)));
          break;
        case 'Mensal':
          incluir =
              dataLancamento.year == now.year &&
              dataLancamento.month == now.month;
          break;
      }

      if (incluir) {
        lancamentosFiltrados.add({"key": lancamento['key'], "value": value});
      }
    }

    // Calcula o saldo total
    double saldo = 0;
    for (var lancamento in lancamentosFiltrados) {
      final value = lancamento['value'] as Map<String, dynamic>;
      saldo += value['valor'] as double;
    }

    setState(() {
      _lancamentos = lancamentosFiltrados;
      _saldoTotal = saldo;
    });
  }

  Future<void> _deletarLancamento(String key) async {
    await box.delete(key);
    _refreshLancamentos();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lançamento excluído com sucesso!'),
        backgroundColor: Colors.red,
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

  void _editarLancamento(String key, Map<String, dynamic> value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LancamentoPage(lancamento: value, lancamentoKey: key),
      ),
    ).then((result) {
      if (result == true) {
        _refreshLancamentos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final backgroundColor = isDarkMode
        ? Color(0xFF1E1E28)
        : const Color.fromARGB(255, 206, 205, 205);
    final cardColor = isDarkMode ? Color(0xFF2C2C36) : Colors.white;
    final positiveColor = isDarkMode ? Colors.greenAccent[400] : Colors.green;
    final negativeColor = isDarkMode ? Colors.redAccent[400] : Colors.red;
    // Formatador de moeda
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
            SizedBox(width: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Meu ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'Caixa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMetaCard ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _showMetaCard = !_showMetaCard;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LancamentoPage()),
              );
              if (result == true) {
                _refreshLancamentos(); // Atualiza a lista após salvar
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.greenAccent,
          tabs: _periodos.map((periodo) => Tab(text: periodo)).toList(),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: _periodos.map((periodo) {
          return RefreshIndicator(
            onRefresh: () async {
              _refreshLancamentos();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
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
                            ? [
                                Colors.indigoAccent[700]!,
                                Colors.indigoAccent[400]!,
                              ]
                            : [Colors.indigo[700]!, Colors.indigo[400]!],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        _saldoTotal >= 0
                                            ? "Positivo"
                                            : "Negativo",
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
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: _metaMensal > 0
                                                ? (_saldoTotal / _metaMensal)
                                                      .clamp(0.0, 1.0)
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${(_saldoTotal / _metaMensal * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                color:
                                                    _saldoTotal >= _metaMensal
                                                    ? Colors.black
                                                    : Colors.indigo[700],
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

                  // Seção da meta mensal (agora condicional)
                  if (_showMetaCard)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Card(
                        color: cardColor,
                        elevation: 4,
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
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: 'Valor da Meta R\$',
                                        prefixIcon: Icon(Icons.flag_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                  SizedBox(height: 8),
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
                  if (_lancamentos.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum lançamento encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _lancamentos.length,
                      itemBuilder: (context, index) {
                        final lancamento = _lancamentos[index];
                        final value =
                            lancamento['value'] as Map<String, dynamic>;
                        final key = lancamento['key'] as String;

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 10,
                          shadowColor: Colors.blue.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getFormaPagamentoIcon(
                                          value['formaPagamento'],
                                        ),
                                        color: Colors.blue.shade700,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            value['descricao'] as String,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(value['data']))}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (value['usuario'] != null &&
                                              value['usuario'].isNotEmpty)
                                            Text(
                                              'Usuário: ${value['usuario']}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Valor',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            currencyFormat.format(
                                              value['valor'],
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (value['valor'] as double) >=
                                                      0
                                                  ? positiveColor
                                                  : negativeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Forma',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            value['formaPagamento'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _editarLancamento(key, value),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deletarLancamento(key),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (value['observacao'] != null &&
                                    value['observacao'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Obs: ${value['observacao']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
