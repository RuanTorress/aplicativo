import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RotinaFormPage extends StatefulWidget {
  final String? rotinaKey;
  final Map<String, dynamic>? rotina;

  const RotinaFormPage({Key? key, this.rotinaKey, this.rotina})
    : super(key: key);

  @override
  _RotinaFormPageState createState() => _RotinaFormPageState();
}

class _RotinaFormPageState extends State<RotinaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataInicioController = TextEditingController();
  final TextEditingController _dataFimController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  String _categoria = 'Pessoal';
  String _prioridade = 'Média';
  bool _concluida = false;
  bool _repetir = false;
  List<int> _diasDaSemana = []; // 1-7, onde 1 é segunda e 7 é domingo
  bool _lembrete = false;
  int _lembreteTempo = 15; // minutos antes

  final List<String> _categorias = [
    'Pessoal',
    'Trabalho',
    'Estudo',
    'Saúde',
    'Outra',
  ];
  final List<String> _prioridades = ['Alta', 'Média', 'Baixa'];
  final box = Hive.box('rotinas');
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    super.dispose();
  }

  void _carregarDados() {
    if (widget.rotina != null) {
      final rotina = widget.rotina!;

      _tituloController.text = rotina['titulo'] ?? '';
      _descricaoController.text = rotina['descricao'] ?? '';

      _dataInicio = DateTime.parse(rotina['dataInicio']);
      _dataInicioController.text = DateFormat('dd/MM/yyyy').format(_dataInicio);

      if (rotina['dataFim'] != null) {
        _dataFim = DateTime.parse(rotina['dataFim']);
        _dataFimController.text = DateFormat('dd/MM/yyyy').format(_dataFim!);
      }

      if (rotina['horaInicio'] != null) {
        final hora = rotina['horaInicio'].split(':');
        _horaInicio = TimeOfDay(
          hour: int.parse(hora[0]),
          minute: int.parse(hora[1]),
        );
        _horaInicioController.text =
            '${hora[0].padLeft(2, '0')}:${hora[1].padLeft(2, '0')}';
      }

      if (rotina['horaFim'] != null) {
        final hora = rotina['horaFim'].split(':');
        _horaFim = TimeOfDay(
          hour: int.parse(hora[0]),
          minute: int.parse(hora[1]),
        );
        _horaFimController.text =
            '${hora[0].padLeft(2, '0')}:${hora[1].padLeft(2, '0')}';
      }

      _categoria = rotina['categoria'] ?? 'Pessoal';
      _prioridade = rotina['prioridade'] ?? 'Média';
      _concluida = rotina['concluida'] ?? false;
      _repetir = rotina['repetir'] ?? false;

      if (rotina['diasDaSemana'] != null) {
        _diasDaSemana = List<int>.from(rotina['diasDaSemana']);
      }

      _lembrete = rotina['lembrete'] ?? false;
      _lembreteTempo = rotina['lembreteTempo'] ?? 15;
    } else {
      _dataInicioController.text = DateFormat('dd/MM/yyyy').format(_dataInicio);
    }
  }

  Future<void> _selecionarDataInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.indigoAccent[700]!
                  : Colors.indigo[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = picked;
        _dataInicioController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_dataInicio);
      });
    }
  }

  Future<void> _selecionarDataFim() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio,
      firstDate: _dataInicio,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.indigoAccent[700]!
                  : Colors.indigo[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataFim = picked;
        _dataFimController.text = DateFormat('dd/MM/yyyy').format(_dataFim!);
      });
    }
  }

  Future<void> _selecionarHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.indigoAccent[700]!
                  : Colors.indigo[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaInicio = picked;
        _horaInicioController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selecionarHoraFim() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaFim ?? (_horaInicio ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.indigoAccent[700]!
                  : Colors.indigo[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaFim = picked;
        _horaFimController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _salvarRotina() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rotina = {
      'titulo': _tituloController.text,
      'descricao': _descricaoController.text,
      'dataInicio': DateFormat('yyyy-MM-dd').format(_dataInicio),
      'dataFim': _dataFim != null
          ? DateFormat('yyyy-MM-dd').format(_dataFim!)
          : null,
      'horaInicio': _horaInicio != null
          ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}'
          : null,
      'horaFim': _horaFim != null
          ? '${_horaFim!.hour.toString().padLeft(2, '0')}:${_horaFim!.minute.toString().padLeft(2, '0')}'
          : null,
      'categoria': _categoria,
      'prioridade': _prioridade,
      'concluida': _concluida,
      'repetir': _repetir,
      'diasDaSemana': _repetir ? _diasDaSemana : [],
      'lembrete': _lembrete,
      'lembreteTempo': _lembreteTempo,
      'dataCriacao':
          widget.rotina != null && widget.rotina!['dataCriacao'] != null
          ? widget.rotina!['dataCriacao']
          : DateTime.now().toIso8601String(),
    };

    if (widget.rotinaKey != null) {
      // Atualizar rotina existente
      await box.put(widget.rotinaKey, rotina);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotina atualizada com sucesso!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      // Criar nova rotina
      final id = uuid.v4();
      await box.put(id, rotina);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotina criada com sucesso!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    Navigator.pop(context, true);
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
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.rotina != null ? 'Editar Rotina' : 'Nova Rotina'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título da Rotina *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              // Seção de Categoria
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoria e Prioridade',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Categoria
                      DropdownButtonFormField<String>(
                        value: _categoria,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            _getCategoriaIcon(_categoria),
                            color: _getCategoriaColor(_categoria),
                          ),
                        ),
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem<String>(
                            value: categoria,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoriaIcon(categoria),
                                  color: _getCategoriaColor(categoria),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(categoria),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _categoria = newValue!;
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // Prioridade
                      Text(
                        'Prioridade',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _prioridades.map((p) {
                          Color cor;
                          IconData icone;

                          switch (p.toLowerCase()) {
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

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _prioridade = p;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _prioridade == p
                                      ? cor.withOpacity(0.2)
                                      : isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _prioridade == p
                                        ? cor
                                        : isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icone,
                                      color: _prioridade == p
                                          ? cor
                                          : Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      p,
                                      style: TextStyle(
                                        color: _prioridade == p ? cor : null,
                                        fontWeight: _prioridade == p
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Seção de Datas e Horas
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datas e Horários',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Data de início
                      GestureDetector(
                        onTap: _selecionarDataInicio,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataInicioController,
                            decoration: InputDecoration(
                              labelText: 'Data de Início *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.event),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, selecione uma data';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Data de fim
                      GestureDetector(
                        onTap: _selecionarDataFim,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataFimController,
                            decoration: InputDecoration(
                              labelText: 'Data de Fim (opcional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.event_available),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Hora de início
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _selecionarHoraInicio,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _horaInicioController,
                                  decoration: InputDecoration(
                                    labelText: 'Hora Início',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _selecionarHoraFim,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _horaFimController,
                                  decoration: InputDecoration(
                                    labelText: 'Hora Fim',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
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
              SizedBox(height: 24),

              // Seção de Repetição
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
                  padding: EdgeInsets.all(16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            value: _repetir,
                            onChanged: (value) {
                              setState(() {
                                _repetir = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                      if (_repetir) ...[
                        SizedBox(height: 16),
                        Text(
                          'Selecione os dias da semana',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (index) {
                            final dia = index + 1;
                            final selecionado = _diasDaSemana.contains(dia);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selecionado) {
                                    _diasDaSemana.remove(dia);
                                  } else {
                                    _diasDaSemana.add(dia);
                                  }
                                });
                              },
                              child: CircleAvatar(
                                backgroundColor: selecionado
                                    ? primaryColor
                                    : isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                                radius: 20,
                                child: Text(
                                  _getDiaSemana(dia),
                                  style: TextStyle(
                                    color: selecionado
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge!.color,
                                    fontWeight: selecionado
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Seção de Lembrete
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
                  padding: EdgeInsets.all(16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            value: _lembrete,
                            onChanged: (value) {
                              setState(() {
                                _lembrete = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                      if (_lembrete) ...[
                        SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _lembreteTempo,
                          decoration: InputDecoration(
                            labelText: 'Lembrar com antecedência',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          items: [5, 10, 15, 30, 60, 120, 1440].map((tempo) {
                            String label;
                            if (tempo < 60) {
                              label = "$tempo minutos antes";
                            } else if (tempo < 1440) {
                              label =
                                  "${tempo ~/ 60} hora${tempo ~/ 60 > 1 ? 's' : ''} antes";
                            } else {
                              label = "1 dia antes";
                            }

                            return DropdownMenuItem<int>(
                              value: tempo,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _lembreteTempo = newValue!;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Status (concluída ou não)
              if (widget.rotina != null)
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
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _concluida
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: _concluida ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Rotina concluída',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Switch(
                          value: _concluida,
                          onChanged: (value) {
                            setState(() {
                              _concluida = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 32),

              // Botão de salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvarRotina,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.rotina != null
                        ? 'Atualizar Rotina'
                        : 'Salvar Rotina',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
