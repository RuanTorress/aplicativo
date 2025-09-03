import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class PacoteScreen extends StatefulWidget {
  @override
  _PacoteScreenState createState() => _PacoteScreenState();
}

class _PacoteScreenState extends State<PacoteScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _descontoController = TextEditingController();
  DateTime _dataCriacao = DateTime.now();

  final Box procedimentosBox = Hive.box('procedimentos');
  final Box pacotesBox = Hive.box('pacotes');

  // Map<indexProcedimento, quantidade>
  Map<int, int> _procedimentosSelecionados = {};

  int get _totalSemDesconto {
    int total = 0;
    _procedimentosSelecionados.forEach((index, qtd) {
      final procedimento = procedimentosBox.getAt(index);
      if (procedimento is Map && procedimento['valor'] != null) {
        total += ((procedimento['valor'] as num) * qtd).round();
      }
    });
    return total;
  }

  double get _totalComDesconto {
    double total = _totalSemDesconto.toDouble();
    double desconto =
        double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0.0;
    if (desconto > 0 && desconto <= 100) {
      total = total * (1 - desconto / 100);
    }
    return total;
  }

  void _limparCampos() {
    _nomeController.clear();
    _descricaoController.clear();
    _descontoController.clear();
    setState(() {
      _procedimentosSelecionados.clear();
      _dataCriacao = DateTime.now();
    });
  }

  void _salvarPacote({int? editIndex}) {
    double? desconto = double.tryParse(
      _descontoController.text.replaceAll(',', '.'),
    );
    if (_nomeController.text.trim().isEmpty ||
        _procedimentosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preencha todos os campos obrigatórios e selecione procedimentos!',
          ),
        ),
      );
      return;
    }
    if (_descontoController.text.trim().isNotEmpty &&
        (desconto == null || desconto < 0 || desconto > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O desconto deve ser um valor entre 0 e 100.')),
      );
      return;
    }
    final procedimentos = _procedimentosSelecionados.entries.map((e) {
      final procedimento = procedimentosBox.getAt(e.key);
      // Armazenamos o procedimento como um mapa para garantir compatibilidade de tipo
      if (procedimento is Map) {
        return {
          'procedimento': Map<String, dynamic>.from(procedimento),
          'quantidade': e.value,
        };
      } else {
        // Para procedimentos que não são mapas, armazenamos um mapa simplificado
        return {
          'procedimento': {'nome': procedimento.toString(), 'valor': 0},
          'quantidade': e.value,
        };
      }
    }).toList();

    final pacote = {
      'nome': _nomeController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'preco': _totalSemDesconto.toStringAsFixed(2),
      'procedimentos': procedimentos,
      'desconto': _descontoController.text.trim(),
      'precoFinal': _totalComDesconto.toStringAsFixed(2),
      'dataCriacao': _dataCriacao.toIso8601String(),
    };

    if (editIndex != null) {
      pacotesBox.putAt(editIndex, pacote);
    } else {
      pacotesBox.add(pacote);
    }
    _limparCampos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(editIndex != null ? 'Pacote editado!' : 'Pacote criado!'),
      ),
    );
  }

  void _removerPacote(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover pacote'),
        content: Text('Tem certeza que deseja remover este pacote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      pacotesBox.deleteAt(index);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pacote removido!')));
    }
  }

  void _editarPacote(int index) {
    final pacote = pacotesBox.getAt(index);
    _nomeController.text = pacote['nome'] ?? '';
    _descricaoController.text = pacote['descricao'] ?? '';
    _descontoController.text = pacote['desconto'] ?? '';
    _dataCriacao =
        DateTime.tryParse(pacote['dataCriacao'] ?? '') ?? DateTime.now();
    _procedimentosSelecionados.clear();
    try {
      for (var item in (pacote['procedimentos'] as List)) {
        if (item is! Map) continue;

        final procedimento = item['procedimento'];
        final quantidade = (item['quantidade'] as num?)?.toInt() ?? 1;

        // Encontrar o índice do procedimento no box
        int idx = -1;
        for (int i = 0; i < procedimentosBox.length; i++) {
          final p = procedimentosBox.getAt(i);
          if (p is Map &&
              procedimento is Map &&
              p['nome'] != null &&
              procedimento['nome'] != null &&
              p['nome'] == procedimento['nome']) {
            idx = i;
            break;
          }
        }
        if (idx != -1) {
          _procedimentosSelecionados[idx] = quantidade;
        }
      }
    } catch (e) {
      print('Erro ao carregar procedimentos do pacote: $e');
      // Não interrompe o fluxo se houver erro
    }
    setState(() {});
    showDialog(
      context: context,
      builder: (_) => _buildPacoteDialog(editIndex: index),
    );
  }

  Widget _buildPacoteDialog({int? editIndex}) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      editIndex == null ? Icons.add_box : Icons.edit_note,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      editIndex == null ? 'Novo Pacote' : 'Editar Pacote',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Pacote',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Text(
                  'Selecione procedimentos e sessões:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 6),
              ValueListenableBuilder(
                valueListenable: procedimentosBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(top: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Nenhum procedimento cadastrado.',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final procedimento = box.getAt(index);
                      String nome =
                          procedimento is Map && procedimento['nome'] != null
                          ? procedimento['nome']
                          : procedimento.toString();
                      double valor =
                          procedimento is Map && procedimento['valor'] != null
                          ? (procedimento['valor'] as num).toDouble()
                          : 0.0;
                      int qtd = (_procedimentosSelecionados[index] ?? 0)
                          .toInt();
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        elevation: qtd > 0 ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: qtd > 0
                                ? Colors.blue.shade300
                                : Colors.grey.shade300,
                            width: qtd > 0 ? 1.5 : 1,
                          ),
                        ),
                        color: qtd > 0 ? Colors.blue.shade50 : Colors.white,
                        child: ListTile(
                          dense: true,
                          horizontalTitleGap: 8,
                          contentPadding: EdgeInsets.only(
                            left: 12,
                            right: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          title: Text(
                            '$nome',
                            style: TextStyle(
                              fontWeight: qtd > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            'R\$ ${valor.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: qtd > 0 ? Colors.blue.shade700 : null,
                              fontSize: 13,
                            ),
                          ),
                          trailing: StatefulBuilder(
                            builder: (context, setInnerState) {
                              int localQtd =
                                  (_procedimentosSelecionados[index] ?? 0)
                                      .toInt();
                              return Container(
                                width: 100, // Reduzido para evitar overflow
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: localQtd > 0
                                          ? () {
                                              setInnerState(() {
                                                setState(() {
                                                  if (localQtd > 1) {
                                                    _procedimentosSelecionados[index] =
                                                        localQtd - 1;
                                                  } else {
                                                    _procedimentosSelecionados
                                                        .remove(index);
                                                  }
                                                });
                                              });
                                            }
                                          : null,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: localQtd > 0
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: localQtd > 0
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      alignment: Alignment.center,
                                      child: Text(
                                        localQtd.toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setInnerState(() {
                                          setState(() {
                                            _procedimentosSelecionados[index] =
                                                localQtd + 1;
                                          });
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (qtd == 0) {
                                _procedimentosSelecionados[index] = 1;
                              } else {
                                _procedimentosSelecionados.remove(index);
                              }
                            });
                          },
                          selected: qtd > 0,
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descontoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Desconto (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                  hintText: 'Opcional',
                  errorText:
                      (_descontoController.text.trim().isNotEmpty &&
                          (double.tryParse(
                                    _descontoController.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  ) ==
                                  null ||
                              double.tryParse(
                                    _descontoController.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  )! <
                                  0 ||
                              double.tryParse(
                                    _descontoController.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  )! >
                                  100))
                      ? 'Valor entre 0 e 100'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data da promoção:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _dataCriacao,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _dataCriacao = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_dataCriacao),
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total sem desconto: R\$ ${_totalSemDesconto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if ((_descontoController.text.trim().isNotEmpty) &&
                        double.tryParse(
                              _descontoController.text.replaceAll(',', '.'),
                            ) !=
                            null)
                      Text(
                        'Total com desconto: R\$ ${_totalComDesconto.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (editIndex == null) _limparCampos();
                    },
                    child: Text('Cancelar', style: TextStyle(fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(90, 45),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text(
                      editIndex == null ? 'Salvar' : 'Salvar',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(120, 45),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _salvarPacote(editIndex: editIndex);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                _limparCampos();
                showDialog(
                  context: context,
                  builder: (_) => _buildPacoteDialog(),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 54,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Novo Pacote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.blue[700],
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Pacotes Disponíveis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: pacotesBox.listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) {
                return Card(
                  elevation: 0,
                  color: Colors.grey[100],
                  margin: EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum pacote cadastrado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Clique em "Novo Pacote" para começar a criar seus pacotes de procedimentos',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final pacote = box.getAt(index);
                  final procedimentos = (pacote['procedimentos'] as List);
                  final desconto = pacote['desconto'] ?? '';
                  final precoFinal = pacote['precoFinal'] ?? pacote['preco'];
                  final dataCriacao = pacote['dataCriacao'] != null
                      ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(DateTime.parse(pacote['dataCriacao']))
                      : '';
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  pacote['nome'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _editarPacote(index),
                                    tooltip: 'Editar',
                                    iconSize: 20,
                                    constraints: BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removerPacote(index),
                                    tooltip: 'Remover',
                                    iconSize: 20,
                                    constraints: BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if ((pacote['descricao'] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                pacote['descricao'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          Text(
                            'Criado em: $dataCriacao',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Preço original: R\$ ${pacote['preco']}',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              if (desconto.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    'Desconto: $desconto%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Text(
                              'Preço final: R\$ $precoFinal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Procedimentos:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          ...procedimentos.map<Widget>((item) {
                            final p = item['procedimento'];
                            final qtd = item['quantidade'] ?? 1;
                            if (p is! Map) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 2,
                                  bottom: 2,
                                ),
                                child: Text(
                                  'Procedimento inválido (tipo: \'${p.runtimeType}\')',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            }
                            String nome = p['nome'] != null
                                ? p['nome']
                                : p.toString();
                            double valor = p['valor'] != null
                                ? (p['valor'] as num).toDouble()
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$nome - $qtd sessão(ões) x R\$ ${valor.toStringAsFixed(2)} = R\$ ${(valor * qtd).toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
