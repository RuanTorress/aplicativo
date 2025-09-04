import 'package:altgest/rotina_diarias.dart/RotinaDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'rotina_form_page.dart';

class RotinasPage extends StatefulWidget {
  @override
  _RotinasPageState createState() => _RotinasPageState();
}

class _RotinasPageState extends State<RotinasPage>
    with SingleTickerProviderStateMixin {
  final box = Hive.box('rotinas');
  List<Map<String, dynamic>> _rotinas = [];
  int _totalRotinas = 0;
  int _rotinasCompletas = 0;
  String _periodoAtual = 'Semanal'; // Padrão: Semanal
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _periodos = ['Diário', 'Semanal', 'Mensal'];
  List<String> _categorias = [
    'Todas',
    'Pessoal',
    'Trabalho',
    'Estudo',
    'Saúde',
  ];
  String _categoriaFiltro = 'Todas';
  bool _showFilters =
      true; // Novo estado para controlar visibilidade dos filtros

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _periodoAtual = _periodos[_tabController.index];
        });
        _refreshRotinas();
      }
    });
    _refreshRotinas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshRotinas() {
    final now = DateTime.now();
    final data = box.keys.map((key) {
      final value = box.get(key);
      return {"key": key, "value": value};
    }).toList();

    // Filtra as rotinas de acordo com o período selecionado
    List<Map<String, dynamic>> rotinasFiltradas = [];

    for (var rotina in data) {
      DateTime dataRotina = DateTime.parse(rotina['value']['dataInicio']);
      DateTime? dataFim = rotina['value']['dataFim'] != null
          ? DateTime.parse(rotina['value']['dataFim'])
          : null;
      bool incluir = false;

      switch (_periodoAtual) {
        case 'Diário':
          incluir =
              DateFormat('yyyy-MM-dd').format(dataRotina) ==
                  DateFormat('yyyy-MM-dd').format(now) ||
              (rotina['value']['repetir'] == true &&
                  _verificarDiaRepetir(rotina['value'], now));
          break;
        case 'Semanal':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          incluir =
              (dataRotina.isAfter(
                    startOfWeek.subtract(const Duration(days: 1)),
                  ) &&
                  dataRotina.isBefore(
                    endOfWeek.add(const Duration(days: 1)),
                  )) ||
              (rotina['value']['repetir'] == true &&
                  _verificarSemanaRepetir(
                    rotina['value'],
                    startOfWeek,
                    endOfWeek,
                  ));
          break;
        case 'Mensal':
          incluir =
              (dataRotina.month == now.month && dataRotina.year == now.year) ||
              (dataFim != null &&
                  dataFim.month == now.month &&
                  dataFim.year == now.year) ||
              (rotina['value']['repetir'] == true &&
                  rotina['value']['diasDaSemana'] != null);
          break;
      }

      // Filtro por categoria
      if (_categoriaFiltro != 'Todas' &&
          rotina['value']['categoria'] != _categoriaFiltro) {
        incluir = false;
      }

      // Filtro por busca
      if (_searchQuery.isNotEmpty &&
          !rotina['value']['titulo'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) &&
          !rotina['value']['descricao'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        incluir = false;
      }

      if (incluir) {
        rotinasFiltradas.add(rotina);
      }
    }

    // Calcula estatísticas
    int rotinasCompletas = 0;
    for (var rotina in rotinasFiltradas) {
      if (rotina['value']['concluida'] == true) {
        rotinasCompletas++;
      }
    }

    setState(() {
      _rotinas = rotinasFiltradas;
      _totalRotinas = rotinasFiltradas.length;
      _rotinasCompletas = rotinasCompletas;
    });
  }

  bool _verificarDiaRepetir(dynamic rotina, DateTime hoje) {
    if (rotina['diasDaSemana'] == null || rotina['diasDaSemana'].isEmpty) {
      return false;
    }

    // Dias da semana vão de 1 (Segunda) a 7 (Domingo) em formato JSON
    // Convertendo para formato do DateTime onde 1 é Segunda e 7 é Domingo
    int diaSemanaHoje = hoje.weekday;
    return rotina['diasDaSemana'].contains(diaSemanaHoje);
  }

  bool _verificarSemanaRepetir(
    dynamic rotina,
    DateTime inicioSemana,
    DateTime fimSemana,
  ) {
    if (rotina['diasDaSemana'] == null || rotina['diasDaSemana'].isEmpty) {
      return false;
    }

    // Verifica se algum dia da semana da rotina cai nessa semana
    return rotina['diasDaSemana'].any((dia) => true);
  }

  Future<void> _alternarConclusaoRotina(String key, bool novoValor) async {
    final rotina = box.get(key);
    rotina['concluida'] = novoValor;
    await box.put(key, rotina);
    _refreshRotinas();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          novoValor ? "Rotina concluída!" : "Rotina desmarcada como concluída",
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: novoValor ? Colors.green[700] : Colors.blueGrey[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deletarRotina(String key) async {
    await box.delete(key);
    _refreshRotinas();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Rotina deletada!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Pessoal':
        return Colors.purple;
      case 'Trabalho':
        return Colors.blue;
      case 'Estudo':
        return Colors.amber.shade800;
      case 'Saúde':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Pessoal':
        return Icons.person;
      case 'Trabalho':
        return Icons.work;
      case 'Estudo':
        return Icons.school;
      case 'Saúde':
        return Icons.favorite;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Definir cores mais profissionais
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final backgroundColor = isDarkMode ? Color(0xFF1E1E28) : Colors.grey[50];
    final cardColor = isDarkMode ? Color(0xFF2D2D3A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // Remove a seta de voltar automática
        centerTitle: false, // Para alinhar à esquerda
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Minhas ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18, // Reduzido para evitar overflow
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'Rotinas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Reduzido para evitar overflow
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
              _showFilters ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RotinaFormPage()),
              );
              if (result == true) {
                _refreshRotinas();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Diário'),
            Tab(text: 'Semanal'),
            Tab(text: 'Mensal'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshRotinas();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cartão do resumo
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [Color(0xFF3949AB), Color(0xFF5C6BC0)]
                        : [Color(0xFF3949AB), Color(0xFF7986CB)],
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
                                'Rotinas $_periodoAtual',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "$_rotinasCompletas/$_totalRotinas Completas",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            _totalRotinas > 0
                                ? "Você completou ${(_rotinasCompletas / _totalRotinas * 100).toStringAsFixed(0)}% das suas rotinas"
                                : "Nenhuma rotina para este período",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          if (_totalRotinas > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _totalRotinas > 0
                                            ? (_rotinasCompletas /
                                                  _totalRotinas)
                                            : 0,
                                        minHeight: 10,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _rotinasCompletas == _totalRotinas
                                                  ? Colors.greenAccent
                                                  : Colors.white,
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

              // Filtros e Busca (agora condicional)
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Card(
                    color: cardColor,
                    elevation: 10, // Adicionado sombra para destacar
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
                            'Filtrar Rotinas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar rotina',
                              prefixIcon: Icon(Icons.search),
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
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _refreshRotinas();
                            },
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Categorias:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categorias.map((categoria) {
                                bool isSelected = _categoriaFiltro == categoria;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(categoria),
                                    selected: isSelected,
                                    selectedColor: isSelected
                                        ? _getCategoriaColor(
                                            categoria,
                                          ).withOpacity(0.2)
                                        : null,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? _getCategoriaColor(categoria)
                                          : null,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        _categoriaFiltro = categoria;
                                      });
                                      _refreshRotinas();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 8),
              // Seção de rotinas
              Container(
                width: double.infinity,
                child: Row(
                  children: [
                    Icon(Icons.event_note, color: primaryColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Suas Rotinas',
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
                        '${_rotinas.length}',
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

              // Lista de rotinas
              _rotinas.isEmpty
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 60,
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma rotina encontrada para este período',
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
                      itemCount: _rotinas.length,
                      itemBuilder: (_, index) {
                        final rotina = _rotinas[index]['value'];
                        final key = _rotinas[index]['key'];
                        final categoria = rotina['categoria'] ?? 'Outra';
                        final concluida = rotina['concluida'] ?? false;
                        final dataInicio = DateTime.parse(rotina['dataInicio']);

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
                            _deletarRotina(key);
                          },
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirmar exclusão'),
                                  content: Text(
                                    'Tem certeza que deseja excluir esta rotina?',
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
                            elevation: 10, // Adicionado sombra para destacar
                            color: cardColor,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDarkMode
                                    ? const Color.fromARGB(255, 10, 10, 10)!
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RotinaDetailPage(
                                      rotinaKey: key,
                                      rotina: rotina,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _refreshRotinas();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
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
                                            color: _getCategoriaColor(
                                              categoria,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _getCategoriaIcon(categoria),
                                            color: _getCategoriaColor(
                                              categoria,
                                            ),
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
                                                rotina['titulo'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  decoration: concluida
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  color: concluida
                                                      ? theme
                                                            .colorScheme
                                                            .onSurfaceVariant
                                                      : null,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 14,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(dataInicio),
                                                    style: TextStyle(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (rotina['repetir'] ==
                                                      true) ...[
                                                    SizedBox(width: 8),
                                                    Icon(
                                                      Icons.repeat,
                                                      size: 14,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: concluida,
                                          onChanged: (bool? value) {
                                            _alternarConclusaoRotina(
                                              key,
                                              value ?? false,
                                            );
                                          },
                                          activeColor: _getCategoriaColor(
                                            categoria,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (rotina['descricao'] != null &&
                                        rotina['descricao']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12.0,
                                        ),
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
                                            '${rotina['descricao']}',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 14,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              decoration: concluida
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getCategoriaColor(
                                                categoria,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getCategoriaIcon(categoria),
                                                  size: 14,
                                                  color: _getCategoriaColor(
                                                    categoria,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  categoria,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getCategoriaColor(
                                                      categoria,
                                                    ),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (rotina['prioridade'] != null)
                                            _buildPrioridadeIndicator(
                                              rotina['prioridade'],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioridadeIndicator(String prioridade) {
    Color cor;
    IconData icone;

    switch (prioridade.toLowerCase()) {
      case 'alta':
        cor = Colors.red;
        icone = Icons.priority_high;
        break;
      case 'média':
        cor = Colors.orange;
        icone = Icons.trending_up;
        break;
      case 'baixa':
        cor = Colors.green;
        icone = Icons.low_priority;
        break;
      default:
        cor = Colors.grey;
        icone = Icons.circle;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          SizedBox(width: 4),
          Text(
            prioridade,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
