import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

part 'notas.g.dart';

@HiveType(typeId: 1)
class Nota extends HiveObject {
  @HiveField(0)
  String titulo;

  @HiveField(1)
  String status;

  @HiveField(2)
  DateTime dataHora;

  @HiveField(3)
  String observacao;

  Nota({
    required this.titulo,
    required this.status,
    required this.dataHora,
    this.observacao = '', // This is fine, empty string is constant
  });
}

class NotasPage extends StatefulWidget {
  @override
  _NotasPageState createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> with TickerProviderStateMixin {
  // Métodos auxiliares
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

  Widget _buildFilterChip(String label, Color? color) {
    final isSelected = _filterStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        checkmarkColor: Colors.white,
        selectedColor: Colors.blue.shade600,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? label : "Todos";
          });
        },
      ),
    );
  }

  Widget _buildNoteCard(Nota nota, int index) {
    final statusColor = statusColors[nota.status] ?? Colors.grey;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(nota.dataHora);
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _adicionarOuEditarNota(nota: nota, index: index),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            nota.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (valor) {
                      if (valor == "editar") {
                        _adicionarOuEditarNota(nota: nota, index: index);
                      } else if (valor == "deletar") {
                        _deletarNota(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "editar",
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Editar"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "deletar",
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Deletar"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                nota.titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                nota.observacao,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: Colors.blue.shade300),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(icon == Icons.note ? Icons.add : Icons.refresh),
            label: Text(buttonLabel),
            onPressed: onPressed ?? () => _adicionarOuEditarNota(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarOuEditarNota({Nota? nota, int? index}) {
    if (nota != null) {
      _tituloController.text = nota.titulo;
      _observacaoController.text = nota.observacao;
      _statusSelecionado = nota.status;
    } else {
      _tituloController.clear();
      _observacaoController.clear();
      _statusSelecionado = "Pendente";
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
                  controller: _tituloController,
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
                  controller: _observacaoController,
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
                        value: _statusSelecionado,
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
                          setState(() {
                            _statusSelecionado = valor!;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.label_important,
                            color: statusColors[_statusSelecionado],
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
                              color: statusColors[_statusSelecionado]!,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: statusColors[_statusSelecionado],
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
              if (_tituloController.text.isNotEmpty) {
                final novaNota = Nota(
                  titulo: _tituloController.text,
                  status: _statusSelecionado,
                  dataHora: DateTime.now(),
                  observacao: _observacaoController.text,
                );
                if (nota == null) {
                  _notasBox.add(novaNota);
                } else {
                  _notasBox.putAt(index!, novaNota);
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

  void _deletarNota(int index) {
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
              _notasBox.deleteAt(index);
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

  bool _matchesFilters(Nota nota) {
    if (_filterStatus != "Todos" && nota.status != _filterStatus) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    return nota.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Notas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade500],
            ),
          ),
        ),
      ),
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
                      _buildFilterChip("Todos", null),
                      ...statusOptions.map(
                        (status) =>
                            _buildFilterChip(status, statusColors[status]),
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
                  return _buildEmptyState(
                    icon: Icons.note,
                    message: "Nenhuma nota cadastrada",
                    buttonLabel: "Criar Primeira Nota",
                  );
                }
                if (filteredNotes.isEmpty) {
                  return _buildEmptyState(
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
                    return _buildNoteCard(nota, originalIndex);
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

    @override
    void dispose() {
      _tituloController.dispose();
      _observacaoController.dispose();
      _searchController.dispose();
      _fabAnimationController.dispose();
      super.dispose();
    }

    void _adicionarOuEditarNota({Nota? nota, int? index}) {
      if (nota != null) {
        // editar
        _tituloController.text = nota.titulo;
        _observacaoController.text = nota.observacao;
        _statusSelecionado = nota.status;
      } else {
        // nova
        _tituloController.clear();
        _observacaoController.clear();
        _statusSelecionado = "Pendente";
      }

      // Use more screen width on mobile for the dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: "Título",
                      hintText: "Digite o título da sua nota",
                      prefixIcon: Icon(
                        Icons.title,
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
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  // Observation text field
                  TextField(
                    controller: _observacaoController,
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
                          value: _statusSelecionado,
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
                            setState(() {
                              _statusSelecionado = valor!;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.label_important,
                              color: statusColors[_statusSelecionado],
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
                                color: statusColors[_statusSelecionado]!,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down_circle,
                            color: statusColors[_statusSelecionado],
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text(nota == null ? "Salvar" : "Atualizar"),
              onPressed: () {
                if (_tituloController.text.isNotEmpty) {
                  final novaNota = Nota(
                    titulo: _tituloController.text,
                    status: _statusSelecionado,
                    dataHora: DateTime.now(),
                    observacao: _observacaoController.text,
                  );

                  if (nota == null) {
                    _notasBox.add(novaNota);
                  } else {
                    _notasBox.putAt(index!, novaNota);
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

    void _deletarNota(int index) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete),
              label: Text("Excluir"),
              onPressed: () {
                _notasBox.deleteAt(index);
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

    bool _matchesFilters(Nota nota) {
      // Check status filter
      if (_filterStatus != "Todos" && nota.status != _filterStatus) {
        return false;
      }

      // Check search query
      if (_searchQuery.isEmpty) {
        return true;
      }
      return nota.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
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

    // Métodos auxiliares precisam vir antes do build
    // ...existing code...

    Widget _buildFilterChip(String label, Color? color) {
      final isSelected = _filterStatus == label;

      return Padding(
        padding: const EdgeInsets.only(right: 6.0), // Reduced padding
        child: FilterChip(
          // Make chips more touch-friendly
          labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
          selected: isSelected,
          checkmarkColor: Colors.white,
          selectedColor: Colors.blue.shade600,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          onSelected: (selected) {
            setState(() {
              _filterStatus = selected ? label : "Todos";
            });
          },
        ),
      );
    }

    Widget _buildNoteCard(Nota nota, int index) {
      final statusColor = statusColors[nota.status] ?? Colors.grey;
      final formattedDate = DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(nota.dataHora);

      return Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _adicionarOuEditarNota(nota: nota, index: index),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              nota.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (valor) {
                        if (valor == "editar") {
                          _adicionarOuEditarNota(nota: nota, index: index);
                        } else if (valor == "deletar") {
                          _deletarNota(index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "editar",
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text("Editar"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "deletar",
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Deletar"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  nota.titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // New observation preview
                Text(
                  nota.observacao,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildEmptyState({
      required IconData icon,
      required String message,
      required String buttonLabel,
      VoidCallback? onPressed,
    }) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.blue.shade300),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(icon == Icons.note ? Icons.add : Icons.refresh),
              label: Text(buttonLabel),
              onPressed: onPressed ?? () => _adicionarOuEditarNota(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
