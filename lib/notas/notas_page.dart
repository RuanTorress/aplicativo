import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'nota_model.dart';
import 'notas_widgets.dart';
import 'notas_dialogs.dart';

export 'nota_model.dart';

class NotasPage extends StatefulWidget {
  @override
  _NotasPageState createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> with TickerProviderStateMixin {
  late Box<Nota> _notasBox;
  final _tituloController = TextEditingController();
  final _observacaoController = TextEditingController();
  String _statusSelecionado = "Pendente";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = "Todos";
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<String> statusOptions = ["Pendente", "Em andamento", "Concluído"];
  final Map<String, Color> statusColors = {
    "Pendente": Colors.amber.shade700,
    "Em andamento": Colors.blue.shade600,
    "Concluído": Colors.green.shade600,
  };

  @override
  void initState() {
    super.initState();
    _notasBox = Hive.box<Nota>('notas');

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _observacaoController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<Nota> _getFilteredNotes() {
    final List<Nota> filteredNotes = [];
    for (int i = 0; i < _notasBox.length; i++) {
      final nota = _notasBox.getAt(i)!;
      if (_matchesFilters(nota)) {
        filteredNotes.add(nota);
      }
    }
    return filteredNotes;
  }

  bool _matchesFilters(Nota nota) {
    if (_filterStatus != "Todos" && nota.status != _filterStatus) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    return nota.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  void _adicionarOuEditarNota({Nota? nota, int? index}) {
    NotasDialogs.showAddEditDialog(
      context: context,
      tituloController: _tituloController,
      observacaoController: _observacaoController,
      statusSelecionado: _statusSelecionado,
      onStatusChanged: (status) {
        setState(() {
          _statusSelecionado = status;
        });
      },
      statusOptions: statusOptions,
      statusColors: statusColors,
      notasBox: _notasBox,
      nota: nota,
      index: index,
    );
  }

  void _deletarNota(int index) {
    NotasDialogs.showDeleteDialog(
      context: context,
      notasBox: _notasBox,
      index: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Pesquisar notas...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.blue.shade600,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Filtrar por status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      NotasWidgets.buildFilterChip(
                        "Todos",
                        null,
                        _filterStatus,
                        (filter) {
                          setState(() {
                            _filterStatus = filter;
                          });
                        },
                      ),
                      ...statusOptions.map(
                        (status) => NotasWidgets.buildFilterChip(
                          status,
                          statusColors[status],
                          _filterStatus,
                          (filter) {
                            setState(() {
                              _filterStatus = filter;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _notasBox.listenable(),
              builder: (context, Box<Nota> box, _) {
                final filteredNotes = _getFilteredNotes();
                if (box.isEmpty) {
                  return NotasWidgets.buildEmptyState(
                    icon: Icons.note,
                    message: "Nenhuma nota cadastrada",
                    buttonLabel: "Criar Primeira Nota",
                    onPressed: () => _adicionarOuEditarNota(),
                  );
                }
                if (filteredNotes.isEmpty) {
                  return NotasWidgets.buildEmptyState(
                    icon: Icons.filter_alt_off,
                    message: "Nenhuma nota corresponde aos filtros",
                    buttonLabel: "Limpar Filtros",
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _filterStatus = "Todos";
                      });
                    },
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final nota = filteredNotes[index];
                    final originalIndex = _notasBox.values.toList().indexOf(
                      nota,
                    );
                    return NotasWidgets.buildNoteCard(
                      nota,
                      originalIndex,
                      statusColors,
                      (nota, index) =>
                          _adicionarOuEditarNota(nota: nota, index: index),
                      _deletarNota,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _adicionarOuEditarNota(),
          label: Row(
            children: [
              Icon(Icons.add),
              const SizedBox(width: 8),
              const Text("Nova Nota"),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
    );
  }
}
