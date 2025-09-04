/* import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('meuBanco');
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
/*  */
  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _refreshItems() {
    final data = box.keys.map((key) {
      final value = box.get(key);
      return {"key": key, "value": value};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  Future<void> _saveItem() async {
    if (_nomeController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor preencha todos os campos")),
      );
      return;
    }

    await box.put(_nomeController.text, _valorController.text);
    _refreshItems();

    _nomeController.clear();
    _valorController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Item salvo com sucesso!")));
  }

  Future<void> _deleteItem(String key) async {
    await box.delete(key);
    _refreshItems();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Item deletado!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removendo a AppBar daqui pois já temos uma no MainScreen
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Adicionar Item",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Nome da chave',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _valorController,
              decoration: InputDecoration(
                hintText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveItem,
              child: Text("Salvar Item"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
            SizedBox(height: 20),
            Text(
              "Itens Salvos (${_items.length})",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text("Nenhum item cadastrado"))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, index) {
                        final currentItem = _items[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(currentItem["key"]),
                            subtitle: Text(currentItem["value"].toString()),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteItem(currentItem["key"]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
 */
