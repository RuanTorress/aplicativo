import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class AgendamentosStore {
  final Box box = Hive.box('agendamentos');

  /// Carrega todos os agendamentos do Hive e organiza por data (somente Y-M-D).
  Map<DateTime, List<Map<String, dynamic>>> loadEvents() {
    final Map<DateTime, List<Map<String, dynamic>>> eventos = {};
    final items = box.keys.map((k) {
      final v = box.get(k);
      return {'key': k, 'value': v};
    }).toList();

    for (var item in items) {
      final Map<String, dynamic> ag = Map<String, dynamic>.from(item['value']);
      // assegura formato ISO string
      final horario = DateTime.parse(ag['horario']);
      final dateOnly = DateTime(horario.year, horario.month, horario.day);
      // inclui a chave no map para uso posterior
      final agWithKey = {...ag, 'key': item['key']};
      eventos.putIfAbsent(dateOnly, () => []).add(agWithKey);
    }

    return eventos;
  }

  /// Retorna lista de agendamentos para uma data (YYYY-MM-DD) com filtros
  List<Map<String, dynamic>> getForDate(
    Map<DateTime, List<Map<String, dynamic>>> eventos,
    DateTime date, {
    String statusFilter = 'Todos',
    String query = '',
  }) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    var list = eventos[dateOnly] != null
        ? List<Map<String, dynamic>>.from(eventos[dateOnly]!)
        : <Map<String, dynamic>>[];

    if (statusFilter != 'Todos') {
      list = list
          .where(
            (a) =>
                (a['status'] ?? '').toString().toLowerCase() ==
                statusFilter.toLowerCase(),
          )
          .toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((a) {
        final titulo = (a['titulo'] ?? '').toString().toLowerCase();
        final cliente = (a['cliente'] ?? '').toString().toLowerCase();
        final profissional = (a['profissional'] ?? '').toString().toLowerCase();
        return titulo.contains(q) ||
            cliente.contains(q) ||
            profissional.contains(q);
      }).toList();
    }

    list.sort(
      (a, b) =>
          DateTime.parse(a['horario']).compareTo(DateTime.parse(b['horario'])),
    );
    return list;
  }

  Future<String> create(Map<String, dynamic> payload) async {
    final id = _uuid.v4();
    await box.put(id, payload);
    return id;
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await box.put(id, payload);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  Future<void> updateStatus(String id, String status) async {
    final ag = Map<String, dynamic>.from(box.get(id));
    ag['status'] = status;
    await box.put(id, ag);
  }
}
