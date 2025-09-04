import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'procedimento/procedimentos.dart';
import 'combo/pacote.dart';

class ProcedimentosTabs extends StatefulWidget {
  @override
  _ProcedimentosTabsState createState() => _ProcedimentosTabsState();
}

class _ProcedimentosTabsState extends State<ProcedimentosTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _adicionarOuEditarProcedimento(
    BuildContext context, {
    int? index,
    Procedimento? procedimento,
  }) {
    final TextEditingController nomeController = TextEditingController(
      text: procedimento?.nome ?? '',
    );
    final TextEditingController valorController = TextEditingController(
      text: procedimento != null ? procedimento.valor.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                index == null ? 'Novo Procedimento' : 'Editar Procedimento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do procedimento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final nome = nomeController.text.trim();
                      final valor =
                          double.tryParse(
                            valorController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      if (nome.isNotEmpty) {
                        final novoProcedimento = Procedimento(
                          nome: nome,
                          valor: valor,
                        ).toMap();
                        final box = Hive.box('procedimentos');
                        if (index == null) {
                          box.add(novoProcedimento);
                        } else {
                          box.putAt(index, novoProcedimento);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text(index == null ? 'Adicionar' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAddPressed(BuildContext context) {
    if (_tabController.index == 0) {
      _adicionarOuEditarProcedimento(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Use o botão "Novo Pacote" na aba Pacote')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final backgroundColor = isDarkMode ? Color(0xFF1E1E28) : Colors.grey[50];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading:
              false, // Remove a seta de voltar automática
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Meus ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Serviços',
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
              icon: Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () => _onAddPressed(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white, // Cor do texto da tab selecionada
            unselectedLabelColor:
                Colors.white70, // Cor do texto da tab não selecionada
            indicatorColor:
                Colors.greenAccent, // Cor do indicador da tab selecionada
            indicatorWeight: 3.0, // Espessura do indicador
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs: [
              Tab(text: 'Lista'),
              Tab(text: 'Pacote/Combo'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ProcedimentosScreen(onAddEdit: _adicionarOuEditarProcedimento),
            PacoteScreen(),
          ],
        ),
      ),
    );
  }
}
