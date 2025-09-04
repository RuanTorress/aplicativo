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
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.blue.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.shade100,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          agendamento == null ? Icons.add_circle : Icons.edit,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          agendamento == null
                              ? 'Novo Agendamento'
                              : 'Editar Agendamento',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFormField(
                          controller: _tituloController,
                          label: 'Título do Serviço *',
                          icon: Icons.work,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _clienteController,
                          label: 'Nome do Cliente *',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _profissionalController,
                          label: 'Profissional *',
                          icon: Icons.badge,
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
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blue.shade600,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => dataAg = picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Colors.blue.shade600,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade400,
                                  width: 2,
                                ),
                              ),
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
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.blue.shade600,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
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
                                    prefixIcon: Icon(
                                      Icons.access_time,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(),
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
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.blue.shade600,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
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
                                    prefixIcon: Icon(
                                      Icons.access_time,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(
                              Icons.check_circle_outline,
                              color: Colors.blue.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.blue.shade700,
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
                                      child: Text(
                                        s,
                                        style: GoogleFonts.poppins(),
                                      ),
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
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 52),
                              child: Icon(
                                Icons.note,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blue.shade100, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.save, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Salvar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// Add this helper method at the end of the file
Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
    ),
    style: GoogleFonts.poppins(),
  );
}
