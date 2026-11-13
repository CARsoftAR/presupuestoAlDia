import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/agenda/data/citas_repository.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';
import 'package:presupuesto_al_dia/features/agenda/presentation/widgets/cita_card.dart';
import 'package:presupuesto_al_dia/features/agenda/presentation/screens/cita_form_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _citasRepo = CitasRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks; // Formato compacto

  List<Cita> _todasLasCitas = [];
  bool _isLoading = true;
  bool _verTodasPendientes = false;

  // Paleta minimalista modo claro
  static const Color orangeAccent = Color(0xFFFF6B00);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color violetAccent = Color(0xFF7C3AED);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  Future<void> _loadCitas() async {
    final citas = await _citasRepo.getAllCitas();
    if (mounted) {
      setState(() {
        _todasLasCitas = citas;
        _isLoading = false;
      });
    }
  }

  List<Cita> _getCitasForDay(DateTime day) {
    return _todasLasCitas.where((cita) {
      return isSameDay(cita.fechaHoraVisita, day);
    }).toList();
  }

  List<Cita> get _citasMostradas {
    if (_verTodasPendientes) {
      return _todasLasCitas.where((c) => !c.completada).toList();
    }
    return _getCitasForDay(_selectedDay);
  }

  Future<void> _toggleCompletada(Cita cita) async {
    if (cita.id == null) return;
    await _citasRepo.toggleCompletada(cita.id!, !cita.completada);
    await _loadCitas();
  }

  Future<void> _toggleAlarma(Cita cita, bool activar) async {
    if (cita.id == null) return;
    await _citasRepo.toggleAlarma(cita.id!, activar, minutosSiActiva: 60);
    await _loadCitas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activar ? 'Alarma programada (1 hora antes)' : 'Alarma cancelada'),
          duration: const Duration(seconds: 2),
          backgroundColor: activar ? orangeAccent : textGray,
        ),
      );
    }
  }

  Future<void> _deleteCita(Cita cita) async {
    if (cita.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('¿Eliminar cita?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará la visita agendada con ${cita.nombreCliente} y se cancelará su alarma.',
          style: const TextStyle(color: textGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _citasRepo.deleteCita(cita.id!);
      await _loadCitas();
    }
  }

  Future<void> _openForm({Cita? cita}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CitaFormScreen(
          cita: cita,
          fechaInicial: _selectedDay,
        ),
      ),
    );
    if (res == true) {
      await _loadCitas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadCitas,
        color: orangeAccent,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Barra superior limpia: Título y Toggle entre Calendario o Todas las Pendientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _verTodasPendientes
                          ? 'Todas las Visitas Pendientes'
                          : Formatters.formatDateLong(_selectedDay),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '${_citasMostradas.length} visitas programadas',
                      style: const TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _verTodasPendientes = !_verTodasPendientes;
                    });
                  },
                  icon: Icon(
                    _verTodasPendientes ? Icons.calendar_month_outlined : Icons.list_alt_rounded,
                    size: 16,
                    color: orangeAccent,
                  ),
                  label: Text(
                    _verTodasPendientes ? 'Calendario' : 'Ver Todas',
                    style: const TextStyle(
                      color: orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: orangeAccent.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selector de fecha compacto (table_calendar) en caja blanca plana
            if (!_verTodasPendientes) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: TableCalendar<Cita>(
                  firstDay: DateTime.now().subtract(const Duration(days: 180)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  eventLoader: _getCitasForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: textDark, size: 20),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: textDark, size: 20),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: violetAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: violetAccent, fontWeight: FontWeight.bold),
                    selectedDecoration: const BoxDecoration(
                      color: orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    markerDecoration: const BoxDecoration(
                      color: greenAccent,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(color: textDark, fontSize: 13),
                    weekendTextStyle: const TextStyle(color: textGray, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lista de Tarjetas de Citas del Día
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: orangeAccent),
                ),
              )
            else if (_citasMostradas.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: textGray.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _verTodasPendientes
                            ? 'No tienes visitas pendientes'
                            : 'Sin visitas agendadas para esta fecha',
                        style: const TextStyle(color: textGray, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agendar Visita'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._citasMostradas.map((cita) {
                return CitaCard(
                  cita: cita,
                  onToggleCompletada: () => _toggleCompletada(cita),
                  onToggleAlarma: (activar) => _toggleAlarma(cita, activar),
                  onEdit: () => _openForm(cita: cita),
                  onDelete: () => _deleteCita(cita),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_agenda_nueva_cita',
        onPressed: () => _openForm(),
        backgroundColor: orangeAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_alarm_rounded, size: 20),
        label: const Text(
          'Nueva Visita',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
