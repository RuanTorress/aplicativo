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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarAlertas();
  }

  Future<void> _carregarAlertas() async {
    setState(() => _isLoading = true);
    await Future.delayed(
      Duration(milliseconds: 500),
    ); // Simular loading para UX
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

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors
              .indigoAccent
              .shade700 // Corrigido: shade700 em vez de [700]
        : Colors.indigo.shade700; // Corrigido: shade700 em vez de [700]
    final backgroundColor = isDarkMode
        ? Color(0xFF1E1E28)
        : Colors.grey.shade50; // Corrigido: shade50 em vez de [50]
    final cardColor = theme.cardColor;
    final accentColor = Colors.orangeAccent;

    final totalAlertas = _alertasAgendamentos.length + _alertasRotinas.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: theme.appBarTheme.foregroundColor,
            ),
            SizedBox(width: 8),
            Text('Alertas do Dia', style: theme.appBarTheme.titleTextStyle),
          ],
        ),
        backgroundColor:
            primaryColor, // Atualizado para usar primaryColor customizado
        elevation: 2,
        shadowColor: theme.shadowColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _carregarAlertas,
              child: totalAlertas == 0
                  ? _buildEmptyState(theme, backgroundColor)
                  : ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        // Cabeçalho informativo
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aqui estão seus alertas do dia. Mantenha-se organizado!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Seções de alertas
                        if (_alertasAgendamentos.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Agendamentos',
                            _alertasAgendamentos.length,
                            Icons.event,
                            primaryColor, // Atualizado
                          ),
                          ..._alertasAgendamentos.map(
                            (ag) => _buildAlertaCard(
                              context: context,
                              titulo: ag['titulo'] ?? '',
                              subtitulo:
                                  'Cliente: ${ag['cliente'] ?? ''} • ${DateFormat('HH:mm').format(DateTime.parse(ag['horario']))}',
                              icone: Icons.event,
                              cor: primaryColor, // Atualizado
                              cardColor: cardColor,
                              isNearTime: _isNearTime(
                                DateTime.parse(ag['horario']),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        if (_alertasRotinas.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Rotinas',
                            _alertasRotinas.length,
                            Icons.schedule,
                            accentColor, // Atualizado para accentColor
                          ),
                          ..._alertasRotinas.map(
                            (rotina) => _buildAlertaCard(
                              context: context,
                              titulo: rotina['titulo'] ?? '',
                              subtitulo:
                                  'Categoria: ${rotina['categoria'] ?? ''} • Prioridade: ${rotina['prioridade'] ?? ''}',
                              icone: Icons.schedule,
                              cor: accentColor, // Atualizado
                              cardColor: cardColor,
                              isNearTime: false,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color backgroundColor) {
    return Container(
      color:
          backgroundColor, // Atualizado para usar backgroundColor customizado
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 120,
              color: theme.disabledColor,
            ),
            SizedBox(height: 20),
            Text(
              'Nenhum alerta para hoje!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Você está em dia com seus compromissos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 12),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaCard({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required Color cardColor,
    required bool isNearTime,
  }) {
    return Card(
      color: cardColor,
      elevation: 8,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: cor.withOpacity(0.2),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withOpacity(0.1),
              radius: 28,
              child: Icon(icone, color: cor, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isNearTime
                      ? BlinkingText(
                          text: titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cor,
                          ),
                        )
                      : Text(
                          titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cor,
                          ),
                        ),
                  SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isNearTime)
              Icon(Icons.warning, color: Colors.redAccent, size: 28),
          ],
        ),
      ),
    );
  }

  bool _isNearTime(DateTime horario) {
    final agora = DateTime.now();
    final diferenca = horario
        .difference(agora)
        .inMinutes; // Mudança para minutos para mais precisão
    return diferenca >= 0 && diferenca <= 60; // Dentro de 1 hora
  }
}

// Widget para texto piscante (melhorado com duração mais suave)
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
      duration: Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
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
