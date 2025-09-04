import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'novo_item.dart';

// Modelo de Item de Estoque
@HiveType(typeId: 0)
class ItemEstoque extends HiveObject {
  @HiveField(0)
  String nome;

  @HiveField(1)
  int quantidade;

  @HiveField(2)
  double valorUnitario;

  @HiveField(3)
  DateTime dataAdicao;

  ItemEstoque({
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
    required this.dataAdicao,
  });
}

// Adapter para Hive
class ItemEstoqueAdapter extends TypeAdapter<ItemEstoque> {
  @override
  final int typeId = 0;

  @override
  ItemEstoque read(BinaryReader reader) {
    return ItemEstoque(
      nome: reader.read(),
      quantidade: reader.read(),
      valorUnitario: reader.read(),
      dataAdicao: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ItemEstoque obj) {
    writer.write(obj.nome);
    writer.write(obj.quantidade);
    writer.write(obj.valorUnitario);
    writer.write(obj.dataAdicao);
  }
}

class EstoquePage extends StatefulWidget {
  const EstoquePage({Key? key}) : super(key: key);

  @override
  _EstoquePageState createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage>
    with SingleTickerProviderStateMixin {
  late Box<ItemEstoque> _estoqueBox;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _estoqueBox = Hive.box<ItemEstoque>('estoque');
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Load sample data if the box is empty
    if (_estoqueBox.isEmpty) {
      _addSampleData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addSampleData() {
    // Only for demonstration - add some sample data if empty
    if (_estoqueBox.isEmpty) {
      _estoqueBox.add(
        ItemEstoque(
          nome: 'Produto Demo 1',
          quantidade: 10,
          valorUnitario: 25.99,
          dataAdicao: DateTime.now().subtract(Duration(days: 5)),
        ),
      );
      _estoqueBox.add(
        ItemEstoque(
          nome: 'Produto Demo 2',
          quantidade: 5,
          valorUnitario: 49.90,
          dataAdicao: DateTime.now().subtract(Duration(days: 2)),
        ),
      );
    }
  }

  void _adicionarOuEditarItem({ItemEstoque? item, int? index}) {
    final TextEditingController nomeController = TextEditingController(
      text: item?.nome ?? '',
    );
    final TextEditingController quantidadeController = TextEditingController(
      text: item?.quantidade.toString() ?? '',
    );
    final TextEditingController valorController = TextEditingController(
      text: item?.valorUnitario.toString() ?? '',
    );
    DateTime data = item?.dataAdicao ?? DateTime.now();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return NovoItemDialog(
              nomeController: nomeController,
              quantidadeController: quantidadeController,
              valorController: valorController,
              data: data,
              onDataChanged: (novaData) {
                setStateDialog(() {
                  data = novaData;
                });
              },
              formKey: _formKey,
              isEdit: item != null,
              onSalvar: () {
                if (_formKey.currentState!.validate()) {
                  final novoItem = ItemEstoque(
                    nome: nomeController.text,
                    quantidade: int.parse(quantidadeController.text),
                    valorUnitario: double.parse(valorController.text),
                    dataAdicao: data,
                  );

                  if (item != null && index != null) {
                    _estoqueBox.putAt(index, novoItem);
                  } else {
                    _estoqueBox.add(novoItem);
                  }

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        item != null
                            ? 'Item editado com sucesso!'
                            : 'Item adicionado com sucesso!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onCancelar: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  void _deletarItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 10),
              Text('Confirmar Exclusão'),
            ],
          ),
          content: Text('Tem certeza que deseja excluir este item do estoque?'),
          actions: [
            TextButton.icon(
              icon: Icon(Icons.cancel),
              label: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete),
              label: Text('Excluir'),
              onPressed: () {
                _estoqueBox.deleteAt(index);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item excluído com sucesso!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  double _calcularTotal() {
    double total = 0;
    for (var item in _estoqueBox.values) {
      if (_matchesSearch(item)) {
        total += item.quantidade * item.valorUnitario;
      }
    }
    return total;
  }

  bool _matchesSearch(ItemEstoque item) {
    if (_searchQuery.isEmpty) return true;
    return item.nome.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  List<ItemEstoque> _getFilteredItems() {
    List<ItemEstoque> items = [];
    for (int i = 0; i < _estoqueBox.length; i++) {
      final item = _estoqueBox.getAt(i)!;
      if (_matchesSearch(item)) {
        items.add(item);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
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
                            text: 'Estoque',
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
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar itens...',
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
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
                        borderSide: BorderSide(color: Colors.blue, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _estoqueBox.listenable(),
                builder: (context, Box<ItemEstoque> box, _) {
                  final filteredItems = _getFilteredItems();

                  if (box.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.blue.shade200,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum item no estoque',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Adicionar Primeiro Item'),
                            onPressed: () => _adicionarOuEditarItem(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum item encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final originalIndex = _estoqueBox.values
                            .toList()
                            .indexOf(filteredItems[index]);
                        final item = filteredItems[index];

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 4,
                                shadowColor: Colors.blue.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2,
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
                                                  item.nome,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Adicionado em ${DateFormat('dd/MM/yyyy').format(item.dataAdicao)}',
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildInfoColumn(
                                              Icons.shopping_cart,
                                              'Quantidade',
                                              '${item.quantidade}',
                                              Colors.green,
                                            ),
                                            _buildInfoColumn(
                                              Icons.attach_money,
                                              'Valor unitário',
                                              'R\$ ${item.valorUnitario.toStringAsFixed(2)}',
                                              Colors.amber.shade800,
                                            ),
                                            _buildInfoColumn(
                                              Icons.calculate,
                                              'Valor total',
                                              'R\$ ${(item.quantidade * item.valorUnitario).toStringAsFixed(2)}',
                                              Colors.purple,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      isSmallScreen
                                          ? Column(
                                              children: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton.icon(
                                                    icon: Icon(Icons.edit),
                                                    label: Text('Editar'),
                                                    onPressed: () =>
                                                        _adicionarOuEditarItem(
                                                          item: item,
                                                          index: originalIndex,
                                                        ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.blue,
                                                      side: BorderSide(
                                                        color: Colors.blue,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    icon: Icon(Icons.delete),
                                                    label: Text('Excluir'),
                                                    onPressed: () =>
                                                        _deletarItem(
                                                          originalIndex,
                                                        ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                OutlinedButton.icon(
                                                  icon: Icon(Icons.edit),
                                                  label: Text('Editar'),
                                                  onPressed: () =>
                                                      _adicionarOuEditarItem(
                                                        item: item,
                                                        index: originalIndex,
                                                      ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.blue,
                                                    side: BorderSide(
                                                      color: Colors.blue,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  icon: Icon(Icons.delete),
                                                  label: Text('Excluir'),
                                                  onPressed: () => _deletarItem(
                                                    originalIndex,
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: isSmallScreen
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor Total do Estoque',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'R\$ ${_calcularTotal().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add_circle),
                            label: Text('Novo Item'),
                            onPressed: () => _adicionarOuEditarItem(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Valor Total do Estoque',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'R\$ ${_calcularTotal().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_circle),
                          label: Text('Novo Item'),
                          onPressed: () => _adicionarOuEditarItem(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
