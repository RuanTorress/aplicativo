import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AlertasPage extends StatefulWidget {
  static void openAlertas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlertasPage()),
    );
  }

  @override
  _AlertasPageState createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage>
    with TickerProviderStateMixin {
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
          final ag = Map<String, dynamic>.from(agendamentosBox.get(key));
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
          final rotina = Map<String, dynamic>.from(rotinasBox.get(key));
          final dataInicio = DateTime.parse(rotina['dataInicio']);
          final dataInicioFormatada = DateFormat(
            'yyyy-MM-dd',
          ).format(dataInicio);
          bool incluir = dataInicioFormatada == hojeFormatado;

          // Verificar repetição
          if (!incluir && rotina['repetir'] == true) {
            final diasSemana = rotina['diasDaSemana'] as List<int>? ?? [];
            incluir = diasSemana.contains(hoje.weekday);
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
    final accentColor = Colors.orangeAccent;

    final totalAlertas = _alertasAgendamentos.length + _alertasRotinas.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 8),
            Text('Alertas do Dia'),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregarAlertas(),
        child: totalAlertas == 0
            ? _buildEmptyState()
            : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Cabeçalho informativo
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [?primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Acesse suas telas de agendamentos e rotinas para mais detalhes!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Seções de alertas
                  if (_alertasAgendamentos.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Agendamentos',
                      _alertasAgendamentos.length,
                      Icons.event,
                      Colors.blue,
                    ),
                    ..._alertasAgendamentos.map(
                      (ag) => _buildAlertaCard(
                        titulo: ag['titulo'] ?? '',
                        subtitulo:
                            'Cliente: ${ag['cliente'] ?? ''} • ${DateFormat('HH:mm').format(DateTime.parse(ag['horario']))}',
                        icone: Icons.event,
                        cor: Colors.blue,
                        cardColor: cardColor,
                        isNearTime: _isNearTime(DateTime.parse(ag['horario'])),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (_alertasRotinas.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Rotinas',
                      _alertasRotinas.length,
                      Icons.schedule,
                      Colors.green,
                    ),
                    ..._alertasRotinas.map(
                      (rotina) => _buildAlertaCard(
                        titulo: rotina['titulo'] ?? '',
                        subtitulo:
                            'Categoria: ${rotina['categoria'] ?? ''} • Prioridade: ${rotina['prioridade'] ?? ''}',
                        icone: Icons.schedule,
                        cor: Colors.green,
                        cardColor: cardColor,
                        isNearTime:
                            false, // Rotinas não têm horário exato, ajuste se necessário
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Nenhum alerta para hoje!',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Você está em dia com seus compromissos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertaCard({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required Color cardColor,
    required bool isNearTime,
  }) {
    return Card(
      color: cardColor,
      elevation: 6,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.2),
          child: Icon(icone, color: cor, size: 30),
        ),
        title: isNearTime
            ? BlinkingText(
                text: titulo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              )
            : Text(
                titulo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
        subtitle: Text(subtitulo, style: TextStyle(fontSize: 14)),
        trailing: isNearTime ? Icon(Icons.warning, color: Colors.red) : null,
      ),
    );
  }

  bool _isNearTime(DateTime horario) {
    final agora = DateTime.now();
    final diferenca = horario.difference(agora).inHours;
    return diferenca >= 0 && diferenca <= 1; // Dentro de 1 hora
  }
}

// Widget para texto piscante
class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const BlinkingText({required this.text, this.style});

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
