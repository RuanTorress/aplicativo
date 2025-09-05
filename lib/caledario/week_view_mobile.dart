import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

typedef DayTap = void Function(DateTime day);
typedef ShowDetail = void Function(String id, Map<String, dynamic> ag);

class WeekViewMobile extends StatelessWidget {
  final Map<DateTime, List<Map<String, dynamic>>> weekMap;
  final DateTime selectedDay;
  final DayTap onDayTap;
  final ShowDetail onShowDetail;

  const WeekViewMobile({
    super.key,
    required this.weekMap,
    required this.selectedDay,
    required this.onDayTap,
    required this.onShowDetail,
  });

  List<DateTime> _sortedDays() {
    final days = weekMap.keys.toList();
    days.sort((a, b) => a.compareTo(b));
    return days;
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

  @override
  Widget build(BuildContext context) {
    final days = _sortedDays();
    final theme = Theme.of(context);

    // card width tuned for mobile (adjust as needed)
    const cardWidth = 120.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                'Semana',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${DateFormat('dd MMM yyyy', 'pt_BR').format(days.isNotEmpty ? days.first : DateTime.now())}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170, // altura suficiente para mostrar data + 2 eventos
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final d = days[i];
              final events = weekMap[d] ?? [];
              final isSelected = isSameDay(d, selectedDay);
              return GestureDetector(
                onTap: () {
                  onDayTap(d);
                },
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12, bottom: 6, top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1B1B1F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: theme.primaryColor, width: 2)
                        : Border.all(color: Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row: weekday + date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat(
                                    'EEE',
                                    'pt_BR',
                                  ).format(d), // Dia da semana em português
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd').format(d),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'MMM',
                                'pt_BR',
                              ).format(d), // Mês em português
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // show up to 2 events compactly
                      if (events.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              '—',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var ev in events.take(2))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () =>
                                        onShowDetail(ev['key'] ?? '', ev),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _colorForStatus(
                                              (ev['status'] ?? '').toString(),
                                            ).withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${DateFormat('HH:mm').format(DateTime.parse(ev['horario']))} ${ev['titulo'] ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (events.length > 2)
                                Text(
                                  '+${events.length - 2} mais',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // optional footer - number of events
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${events.length} ag.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
