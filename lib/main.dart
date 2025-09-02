import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive para Web/Mobile
  await Hive.initFlutter();

  // Abre a box (como se fosse uma tabela)
  await Hive.openBox('meuBanco');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novo aplicativo teste',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('meuBanco');
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Carrega os itens quando o app inicia
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // Função para carregar itens do banco
  void _refreshItems() {
    final data = box.keys.map((key) {
      final value = box.get(key);
      return {"key": key, "value": value};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  // Salvar novo item
  Future<void> _saveItem() async {
    if (_nomeController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor preencha todos os campos")),
      );
      return;
    }

    await box.put(_nomeController.text, _valorController.text);
    _refreshItems();

    // Limpa campos após salvar
    _nomeController.clear();
    _valorController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Item salvo com sucesso!")));
  }

  // Deletar um item
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
      appBar: AppBar(title: Text("PWA com Hive - ${_items.length} itens")),
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
