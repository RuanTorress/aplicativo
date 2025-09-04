import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

typedef OnEdit = void Function(String id);
typedef OnDelete = Future<void> Function(String id);
typedef OnShowDetail =
    void Function(String id, Map<String, dynamic> agendamento);
typedef OnUpdateStatus = Future<void> Function(String id, String status);

class AgendamentoCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> ag;
  final OnEdit onEdit;
  final OnDelete onDelete;
  final OnShowDetail onShowDetail;
  final OnUpdateStatus onUpdateStatus;

  const AgendamentoCard({
    Key? key,
    required this.id,
    required this.ag,
    required this.onEdit,
    required this.onDelete,
    required this.onShowDetail,
    required this.onUpdateStatus,
  }) : super(key: key);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.blue;
      case 'pendente':
        return Colors.amber;
      case 'cancelado':
        return Colors.red;
      case 'concluído':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Icons.check_circle;
      case 'pendente':
        return Icons.access_time;
      case 'cancelado':
        return Icons.cancel;
      case 'concluído':
        return Icons.task_alt;
      default:
        return Icons.circle;
    }
  }

  IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('cabelo')) return Icons.content_cut;
    if (t.contains('manicure')) return Icons.clean_hands;
    if (t.contains('massagem')) return Icons.spa;
    if (t.contains('pele')) return Icons.face;
    if (t.contains('sobrancelha')) return Icons.face_retouching_natural;
    if (t.contains('depilação')) return Icons.waves;
    if (t.contains('hidratação')) return Icons.water_drop;
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horario = DateTime.parse(ag['horario']);
    final fim = DateTime.parse(ag['fim']);
    final status = (ag['status'] ?? '').toString();
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(id),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Excluir',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onShowDetail(id, ag),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForTitle(ag['titulo'] ?? ''),
                      size: 20,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ag['titulo'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(horario)} - ${DateFormat('HH:mm').format(fim)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Cliente: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    ag['cliente'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ag['profissional'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
class AgendamentosEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const AgendamentosEmpty({Key? key, required this.onCreate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento encontrado',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente selecionar outra data ou alterar os filtros',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Novo Agendamento'),
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet detail builder (you can also use a StatefulBuilder on showModalBottomSheet)
Widget buildDetailBottomSheet(
  BuildContext context,
  Map<String, dynamic> ag,
  OnEdit onEdit,
  OnUpdateStatus onUpdateStatus,
  OnDelete onDelete,
) {
  final theme = Theme.of(context);
  final horario = DateTime.parse(ag['horario']);
  final fim = DateTime.parse(ag['fim']);
  final status = (ag['status'] ?? '').toString();
  Color statusColor;
  IconData statusIcon;

  switch (status.toLowerCase()) {
    case 'confirmado':
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
      break;
    case 'pendente':
      statusColor = Colors.amber;
      statusIcon = Icons.access_time;
      break;
    case 'cancelado':
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      break;
    case 'concluído':
      statusColor = Colors.green;
      statusIcon = Icons.task_alt;
      break;
    default:
      statusColor = Colors.grey;
      statusIcon = Icons.circle;
  }

  return Container(
    height: MediaQuery.of(context).size.height * 0.7,
    decoration: BoxDecoration(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF1E1E2E)
          : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event, color: statusColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ag['titulo'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem(Icons.person, 'Cliente', ag['cliente'] ?? ''),
                const Divider(height: 32),
                _detailItem(
                  Icons.people,
                  'Profissional',
                  ag['profissional'] ?? '',
                ),
                const Divider(height: 32),
                _detailItem(
                  Icons.access_time,
                  'Horário',
                  '${DateFormat('dd/MM/yyyy').format(horario)} • ${DateFormat('HH:mm').format(horario)} - ${DateFormat('HH:mm').format(fim)}',
                ),
                const Divider(height: 32),
                _detailItem(
                  Icons.timer,
                  'Duração',
                  '${fim.difference(horario).inMinutes} minutos',
                ),
                if (ag['observacao'] != null) ...[
                  const Divider(height: 32),
                  _detailItem(
                    Icons.notes,
                    'Observações',
                    ag['observacao'] ?? '',
                  ),
                ],
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit(ag['key']);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (ag['status'].toString().toLowerCase() != 'cancelado')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: () async {
                            await onUpdateStatus(ag['key'], 'Cancelado');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _detailItem(IconData icon, String title, String content) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.blue),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
