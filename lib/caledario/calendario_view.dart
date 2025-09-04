import 'package:altgest/caledario/week_view_mobile.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import 'agendamentos_store.dart';
import 'agendamento_widgets.dart';
import 'agendamento_form.dart';

class CalendarioAgendamentosPage extends StatefulWidget {
  const CalendarioAgendamentosPage({Key? key}) : super(key: key);

  @override
  _CalendarioAgendamentosPageState createState() =>
      _CalendarioAgendamentosPageState();
}

class _CalendarioAgendamentosPageState extends State<CalendarioAgendamentosPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final store = AgendamentosStore();
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  List<Map<String, dynamic>> _selecionados = [];

  String _statusFiltro = 'Todos';
  String _pesquisa = '';
  final _searchController = TextEditingController();

  final _statusOptions = [
    'Todos',
    'Confirmado',
    'Pendente',
    'Cancelado',
    'Concluído',
  ];

  // Day view controls
  DateTime _dayViewDate = DateTime.now();
  final int _startHour = 7;
  final int _endHour = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reloadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _reloadAll() {
    _eventos = store.loadEvents();
    _selecionados = store.getForDate(
      _eventos,
      _selectedDay,
      statusFilter: _statusFiltro,
      query: _pesquisa,
    );
    setState(() {});
  }

  void _onDaySelected(DateTime sel, DateTime foc) {
    setState(() {
      _selectedDay = sel;
      _focusedDay = foc;
      _dayViewDate = sel;
      _selecionados = store.getForDate(
        _eventos,
        _selectedDay,
        statusFilter: _statusFiltro,
        query: _pesquisa,
      );
    });
  }

  Future<void> _onDelete(String id) async {
    await store.delete(id);
    _reloadAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento excluído!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onEdit(String id) async {
    final ag = await Future.value(store.box.get(id));
    final saved = await showAgendamentoForm(
      context,
      id: id,
      agendamento: Map<String, dynamic>.from(ag as Map),
    );
    if (saved) _reloadAll();
  }

  void _onShowDetail(String id, Map<String, dynamic> ag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => buildDetailBottomSheet(
        ctx,
        ag,
        (eid) => _onEdit(eid),
        (eid, status) async => await store.updateStatus(eid, status),
        (eid) async => await _onDelete(eid),
      ),
    );
  }

  Future<void> _onCreate() async {
    final saved = await showAgendamentoForm(context);
    if (saved) _reloadAll();
  }

  // --- HELPERS FOR DAY / WEEK VIEW ---

  /// retorna mapa hora -> lista de agendamentos para o dia especificado
  Map<int, List<Map<String, dynamic>>> _getEventsByHour(DateTime day) {
    final events = store.getForDate(
      _eventos,
      day,
      statusFilter: _statusFiltro,
      query: _pesquisa,
    );
    final Map<int, List<Map<String, dynamic>>> byHour = {};
    for (var e in events) {
      final dt = DateTime.parse(e['horario']);
      final hour = dt.hour;
      byHour.putIfAbsent(hour, () => []).add(e);
    }
    return byHour;
  }

  /// retorna o mapa de dias da semana (domingo..sábado) para a semana do focusedDay
  Map<DateTime, List<Map<String, dynamic>>> _getEventsForWeek(
    DateTime focused,
  ) {
    final startOfWeek = focused.subtract(Duration(days: focused.weekday - 1));
    final Map<DateTime, List<Map<String, dynamic>>> weekMap = {};
    for (int i = 0; i < 7; i++) {
      final d = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );
      weekMap[d] = store.getForDate(
        _eventos,
        d,
        statusFilter: _statusFiltro,
        query: _pesquisa,
      );
    }
    return weekMap;
  }

  // --- UI BUILDERS ---

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E2E)
            : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        calendarFormat: _calendarFormat,
        onDaySelected: _onDaySelected,
        onFormatChanged: (f) => setState(() => _calendarFormat = f),
        onPageChanged: (f) => _focusedDay = f,
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          return _eventos[key] ?? [];
        },
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: GoogleFonts.poppins(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF1E1E2E)
          : Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar agendamentos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
        ),
        onChanged: (v) {
          setState(() {
            _pesquisa = v;
            _selecionados = store.getForDate(
              _eventos,
              _selectedDay,
              statusFilter: _statusFiltro,
              query: _pesquisa,
            );
          });
        },
      ),
    );
  }

  Widget _buildList() {
    if (_selecionados.isEmpty) {
      return AgendamentosEmpty(onCreate: _onCreate);
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _selecionados.length,
        itemBuilder: (ctx, i) {
          final ag = _selecionados[i];
          final id = ag['key'] ?? '';
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AgendamentoCard(
                    id: id,
                    ag: ag,
                    onEdit: _onEdit,
                    onDelete: _onDelete,
                    onShowDetail: _onShowDetail,
                    onUpdateStatus: (eid, status) async =>
                        await store.updateStatus(eid, status),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- DAY VIEW: timeline per hora com eventos ---
  Widget _buildDayView(BuildContext context) {
    final day = _dayViewDate;
    final byHour = _getEventsByHour(day);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _dayViewDate = _dayViewDate.subtract(
                      const Duration(days: 1),
                    );
                    _selectedDay = _dayViewDate;
                    _focusedDay = _dayViewDate;
                    _selecionados = store.getForDate(
                      _eventos,
                      _selectedDay,
                      statusFilter: _statusFiltro,
                      query: _pesquisa,
                    );
                  });
                },
              ),
              Expanded(
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(day),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _dayViewDate = _dayViewDate.add(const Duration(days: 1));
                    _selectedDay = _dayViewDate;
                    _focusedDay = _dayViewDate;
                    _selecionados = store.getForDate(
                      _eventos,
                      _selectedDay,
                      statusFilter: _statusFiltro,
                      query: _pesquisa,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            itemCount: _endHour - _startHour + 1,
            itemBuilder: (ctx, idx) {
              final hour = _startHour + idx;
              final events = byHour[hour] ?? [];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E1E2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: events.isEmpty
                            ? SizedBox(
                                height: 36,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '—',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: events.map((ag) {
                                  final id = ag['key'] ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      onTap: () => _onShowDetail(id, ag),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _colorForStatus(
                                            ag['status'],
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: _colorForStatus(
                                              ag['status'],
                                            ).withOpacity(0.15),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _smallIconForTitle(
                                                ag['titulo'] ?? '',
                                              ),
                                              size: 18,
                                              color: _colorForStatus(
                                                ag['status'],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${ag['titulo'] ?? ''} • ${ag['cliente'] ?? ''}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              DateFormat('HH:mm').format(
                                                DateTime.parse(ag['horario']),
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _colorForStatus(String status) {
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

  IconData _smallIconForTitle(String title) {
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

  /*   // --- WEEK VIEW: mostra 7 dias com resumo e evento dentro de cada dia ---
  Widget _buildWeekView(BuildContext context) {
    final weekMap = _getEventsForWeek(_focusedDay);
    final days = weekMap.keys.toList()..sort();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                    _reloadAll();
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Semana de ${DateFormat('dd MMM yyyy').format(days.first)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.add(const Duration(days: 7));
                    _reloadAll();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: days.map((d) {
                  final events = weekMap[d] ?? [];
                  final isSelected = isSameDay(d, _selectedDay);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = d;
                          _dayViewDate = d;
                          _focusedDay = d;
                          _selecionados = store.getForDate(
                            _eventos,
                            _selectedDay,
                            statusFilter: _statusFiltro,
                            query: _pesquisa,
                          );
                        });
                        _tabController.animateTo(
                          1,
                        ); // ir para DAY view ao tocar
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.08)
                              : Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E1E2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
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
                            Text(
                              DateFormat('EEE', 'pt_BR').format(d), // Dia da semana em português
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM', 'pt_BR').format(d), // Mês em português
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (events.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '—',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: events.take(4).map((ag) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _colorForStatus(
                                        ag['status'],
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _smallIconForTitle(
                                            ag['titulo'] ?? '',
                                          ),
                                          size: 14,
                                          color: _colorForStatus(ag['status']),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${DateFormat('HH:mm').format(DateTime.parse(ag['horario']))} ${ag['titulo']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (events.length > 4)
                              Text(
                                '+${events.length - 4} mais',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  } */

  // reutilitários e builds principais

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          'Agenda',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E2E)
            : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _onCreate),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Agenda'),
            Tab(text: 'Dia'),
            Tab(text: 'Semana'),
          ],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _buildCalendar(),
              _buildSearchBar(),
              Expanded(child: _buildList()),
            ],
          ),
          _buildDayView(context),
          WeekViewMobile(
            weekMap: _getEventsForWeek(_focusedDay),
            selectedDay: _selectedDay,
            onDayTap: (d) {
              setState(() {
                _selectedDay = d;
                _focusedDay = d;
                _selecionados = store.getForDate(
                  _eventos,
                  _selectedDay,
                  statusFilter: _statusFiltro,
                  query: _pesquisa,
                );
              });
              _tabController.animateTo(1); // opcional: ir para a aba DIA
            },
            onShowDetail: (id, ag) => _onShowDetail(id, ag),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar Agendamentos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOptions.map((s) {
                      final isSel = _statusFiltro == s;
                      final color = s == 'Todos'
                          ? Colors.grey
                          : _getStatusColor(s);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _statusFiltro = s);
                          this.setState(
                            () => _selecionados = store.getForDate(
                              _eventos,
                              _selectedDay,
                              statusFilter: _statusFiltro,
                              query: _pesquisa,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? color.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSel ? color : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (s != 'Todos')
                                Icon(
                                  _getStatusIcon(s),
                                  size: 16,
                                  color: isSel ? color : Colors.grey,
                                ),
                              if (s != 'Todos') const SizedBox(width: 4),
                              Text(
                                s,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSel ? color : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(
                          () => _selecionados = store.getForDate(
                            _eventos,
                            _selectedDay,
                            statusFilter: _statusFiltro,
                            query: _pesquisa,
                          ),
                        );
                      },
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
