import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

/// Abre um diálogo para criar/editar agendamento.
/// - [id] se informado indica edição; [data] pode passar um DateTime inicial.
/// - Retorna true se salvou (feche o diálogo).
Future<bool> showAgendamentoForm(
  BuildContext context, {
  String? id,
  Map<String, dynamic>? agendamento,
}) async {
  final box = Hive.box('agendamentos');
  final uuid = Uuid();

  final _tituloController = TextEditingController();
  final _clienteController = TextEditingController();
  final _profissionalController = TextEditingController();
  final _observacaoController = TextEditingController();

  String status = 'Confirmado';
  DateTime dataAg = DateTime.now();
  TimeOfDay horaInicio = TimeOfDay.now();
  TimeOfDay horaFim = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );

  if (agendamento != null) {
    _tituloController.text = agendamento['titulo'] ?? '';
    _clienteController.text = agendamento['cliente'] ?? '';
    _profissionalController.text = agendamento['profissional'] ?? '';
    _observacaoController.text = agendamento['observacao'] ?? '';
    status = agendamento['status'] ?? status;
    final horario = DateTime.parse(agendamento['horario']);
    final fim = DateTime.parse(agendamento['fim']);
    dataAg = horario;
    horaInicio = TimeOfDay(hour: horario.hour, minute: horario.minute);
    horaFim = TimeOfDay(hour: fim.hour, minute: fim.minute);
  }

  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agendamento == null
                        ? 'Novo Agendamento'
                        : 'Editar Agendamento',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        TextField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: 'Título do Serviço *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _clienteController,
                          decoration: InputDecoration(
                            labelText: 'Nome do Cliente *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _profissionalController,
                          decoration: InputDecoration(
                            labelText: 'Profissional *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataAg,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) setState(() => dataAg = picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(dataAg),
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: horaInicio,
                                  );
                                  if (picked != null)
                                    setState(() => horaInicio = picked);
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Início',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: const Icon(Icons.access_time),
                                  ),
                                  child: Text(
                                    '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: horaFim,
                                  );
                                  if (picked != null)
                                    setState(() => horaFim = picked);
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fim',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: const Icon(Icons.access_time),
                                  ),
                                  child: Text(
                                    '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              [
                                    'Confirmado',
                                    'Pendente',
                                    'Cancelado',
                                    'Concluído',
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => status = v ?? status),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _observacaoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Observações',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_tituloController.text.isEmpty ||
                              _clienteController.text.isEmpty ||
                              _profissionalController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Preencha todos os campos obrigatórios',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final horarioInicio = DateTime(
                            dataAg.year,
                            dataAg.month,
                            dataAg.day,
                            horaInicio.hour,
                            horaInicio.minute,
                          );
                          final horarioFim = DateTime(
                            dataAg.year,
                            dataAg.month,
                            dataAg.day,
                            horaFim.hour,
                            horaFim.minute,
                          );

                          if (!horarioFim.isAfter(horarioInicio)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'O horário de término deve ser posterior ao início',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final payload = {
                            'titulo': _tituloController.text,
                            'cliente': _clienteController.text,
                            'profissional': _profissionalController.text,
                            'horario': horarioInicio.toIso8601String(),
                            'fim': horarioFim.toIso8601String(),
                            'status': status,
                            'observacao': _observacaoController.text.isEmpty
                                ? null
                                : _observacaoController.text,
                            'dataCriacao': DateTime.now().toIso8601String(),
                          };

                          if (id != null) {
                            await box.put(id, payload);
                          } else {
                            final newId = uuid.v4();
                            await box.put(newId, payload);
                          }

                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((v) => v ?? false);
}
