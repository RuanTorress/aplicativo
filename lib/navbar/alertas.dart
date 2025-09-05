import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AlertasPage extends StatefulWidget {
  // Adicione este método estático
  static void openAlertas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlertasPage()),
    );
  }

  @override
  _AlertasPageState createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  final Box agendamentosBox = Hive.box('agendamentos');
  final Box rotinasBox = Hive.box('rotinas');

  List<Map<String, dynamic>> _alertasAgendamentos = [];
  List<Map<String, dynamic>> _alertasRotinas = [];

  @override
  void initState() {
    super.initState();
    _carregarAlertas();
  }

  void _carregarAlertas() {
    final hoje = DateTime.now();
    final hojeFormatado = DateFormat('yyyy-MM-dd').format(hoje);

    // Carregar agendamentos do dia
    _alertasAgendamentos = agendamentosBox.keys
        .map((key) {
          final ag = Map<String, dynamic>.from(
            agendamentosBox.get(key),
          ); // Correção: Converte LinkedMap
          final horario = DateTime.parse(ag['horario']);
          final dataAgendamento = DateFormat('yyyy-MM-dd').format(horario);
          if (dataAgendamento == hojeFormatado) {
            return {'key': key, ...ag};
          }
          return null;
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();

    // Carregar rotinas do dia (considerando repetições)
    _alertasRotinas = rotinasBox.keys
        .map((key) {
          final rotina = Map<String, dynamic>.from(
            rotinasBox.get(key),
          ); // Correção: Converte LinkedMap
          final dataInicio = DateTime.parse(rotina['dataInicio']);
          final dataInicioFormatada = DateFormat(
            'yyyy-MM-dd',
          ).format(dataInicio);
          bool incluir = dataInicioFormatada == hojeFormatado;

          // Verificar repetição
          if (!incluir && rotina['repetir'] == true) {
            final diasSemana = rotina['diasDaSemana'] as List<int>? ?? [];
            incluir = diasSemana.contains(hoje.weekday); // 1=Seg, 7=Dom
          }

          if (incluir) {
            return {'key': key, ...rotina};
          }
          return null;
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1E1E28) : Colors.grey[50];
    final cardColor = isDarkMode ? Color(0xFF2D2D3A) : Colors.white;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];

    final totalAlertas = _alertasAgendamentos.length + _alertasRotinas.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Alertas do Dia'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregarAlertas(),
        child: totalAlertas == 0
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum alerta para hoje!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Você está em dia com seus compromissos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  if (_alertasAgendamentos.isNotEmpty) ...[
                    Text(
                      'Agendamentos (${_alertasAgendamentos.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._alertasAgendamentos.map(
                      (ag) => _buildAlertaCard(
                        titulo: ag['titulo'] ?? '',
                        subtitulo:
                            'Cliente: ${ag['cliente'] ?? ''} • ${DateFormat('HH:mm').format(DateTime.parse(ag['horario']))}',
                        icone: Icons.event,
                        cor: Colors.blue,
                        cardColor: cardColor,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (_alertasRotinas.isNotEmpty) ...[
                    Text(
                      'Rotinas (${_alertasRotinas.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._alertasRotinas.map(
                      (rotina) => _buildAlertaCard(
                        titulo: rotina['titulo'] ?? '',
                        subtitulo:
                            'Categoria: ${rotina['categoria'] ?? ''} • Prioridade: ${rotina['prioridade'] ?? ''}',
                        icone: Icons.schedule,
                        cor: Colors.green,
                        cardColor: cardColor,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildAlertaCard({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required Color cardColor,
  }) {
    return Card(
      color: cardColor,
      elevation: 4,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.1),
          child: Icon(icone, color: cor),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
      ),
    );
  }
}
