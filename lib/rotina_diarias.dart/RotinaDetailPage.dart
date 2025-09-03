import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'rotina_form_page.dart';

class RotinaDetailPage extends StatefulWidget {
  final String rotinaKey;
  final Map<String, dynamic> rotina;

  const RotinaDetailPage({
    Key? key,
    required this.rotinaKey,
    required this.rotina,
  }) : super(key: key);

  @override
  _RotinaDetailPageState createState() => _RotinaDetailPageState();
}

class _RotinaDetailPageState extends State<RotinaDetailPage> {
  late Map<String, dynamic> _rotina;
  final box = Hive.box('rotinas');

  @override
  void initState() {
    super.initState();
    _rotina = Map<String, dynamic>.from(widget.rotina);
  }

  Future<void> _alternarConclusaoRotina(bool novoValor) async {
    setState(() {
      _rotina['concluida'] = novoValor;
    });

    await box.put(widget.rotinaKey, _rotina);

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

  Future<void> _deletarRotina() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir esta rotina?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Excluir'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirmacao == true) {
      await box.delete(widget.rotinaKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rotina deletada!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, true);
    }
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

  String _getDiaSemana(int dia) {
    switch (dia) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          SizedBox(width: 6),
          Text(
            'Prioridade $prioridade',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cor,
            ),
          ),
        ],
      ),
    );
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

    final categoria = _rotina['categoria'] ?? 'Outra';
    final prioridade = _rotina['prioridade'] ?? 'Média';
    final concluida = _rotina['concluida'] ?? false;
    final repetir = _rotina['repetir'] ?? false;
    final diasDaSemana = _rotina['diasDaSemana'] ?? [];
    final lembrete = _rotina['lembrete'] ?? false;
    final lembreteTempo = _rotina['lembreteTempo'] ?? 15;

    final dataInicio = DateTime.parse(_rotina['dataInicio']);
    final dataFim = _rotina['dataFim'] != null
        ? DateTime.parse(_rotina['dataFim'])
        : null;
    final horaInicio = _rotina['horaInicio'];
    final horaFim = _rotina['horaFim'];

    final dataFormatada = DateFormat('dd/MM/yyyy').format(dataInicio);
    final dataFimFormatada = dataFim != null
        ? DateFormat('dd/MM/yyyy').format(dataFim)
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Detalhes da Rotina'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RotinaFormPage(
                    rotinaKey: widget.rotinaKey,
                    rotina: _rotina,
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  _rotina = box.get(widget.rotinaKey);
                });
              }
            },
          ),
          IconButton(icon: Icon(Icons.delete), onPressed: _deletarRotina),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com título, categoria e status
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: concluida
                      ? Colors.green.withOpacity(0.5)
                      : isDarkMode
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                  width: concluida ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rotina['titulo'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  decoration: concluida
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: concluida
                                      ? theme.colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
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
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getCategoriaIcon(categoria),
                                          size: 14,
                                          color: _getCategoriaColor(categoria),
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
                                  SizedBox(width: 8),
                                  _buildPrioridadeIndicator(prioridade),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: concluida,
                            onChanged: (bool? value) {
                              _alternarConclusaoRotina(value ?? false);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (_rotina['descricao'] != null &&
                        _rotina['descricao'].toString().isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          _rotina['descricao'],
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          concluida ? 'Concluída' : 'Não concluída',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: concluida ? Colors.green : Colors.orange,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _alternarConclusaoRotina(!concluida);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: concluida
                                ? Colors.blueGrey
                                : Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            concluida
                                ? 'Marcar como não concluída'
                                : 'Marcar como concluída',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Datas e horários
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Datas e Horários',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.event, color: Colors.blue),
                      title: Text('Data de Início'),
                      subtitle: Text(dataFormatada),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (dataFimFormatada != null)
                      ListTile(
                        leading: Icon(
                          Icons.event_available,
                          color: Colors.green,
                        ),
                        title: Text('Data de Fim'),
                        subtitle: Text(dataFimFormatada),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (horaInicio != null)
                      ListTile(
                        leading: Icon(Icons.access_time, color: Colors.amber),
                        title: Text('Hora de Início'),
                        subtitle: Text(horaInicio),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (horaFim != null)
                      ListTile(
                        leading: Icon(Icons.timer_off, color: Colors.orange),
                        title: Text('Hora de Fim'),
                        subtitle: Text(horaFim),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Repetição
            if (repetir)
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.repeat, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Repetição',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Esta rotina se repete nos seguintes dias:',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: diasDaSemana.map<Widget>((dia) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              _getDiaSemana(dia),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Lembretes
            if (lembrete)
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Lembretes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.alarm, color: Colors.purple),
                        title: Text('Lembrete ativado'),
                        subtitle: Text(_formatarTempoLembrete(lembreteTempo)),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatarTempoLembrete(int tempo) {
    if (tempo < 60) {
      return "$tempo minutos antes";
    } else if (tempo < 1440) {
      return "${tempo ~/ 60} hora${tempo ~/ 60 > 1 ? 's' : ''} antes";
    } else {
      return "1 dia antes";
    }
  }
}
