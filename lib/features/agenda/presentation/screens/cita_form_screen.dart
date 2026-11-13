import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/agenda/data/citas_repository.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';

class CitaFormScreen extends StatefulWidget {
  final Cita? cita;
  final DateTime? fechaInicial;

  const CitaFormScreen({
    super.key,
    this.cita,
    this.fechaInicial,
  });

  @override
  State<CitaFormScreen> createState() => _CitaFormScreenState();
}

class _CitaFormScreenState extends State<CitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citasRepo = CitasRepository();

  late TextEditingController _clienteCtrl;
  late TextEditingController _establecimientoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _celularCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _customMinutosCtrl;

  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;
  late int _minutosAnticipacion;
  bool _isCustomAlarma = false;

  // Paleta minimalista modo claro
  static const Color orangeAccent = Color(0xFFFF6B00);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color violetAccent = Color(0xFF7C3AED);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);

  // Pills de presets rápidos requeridos
  final List<int> _alarmPresets = [30, 60, 120];

  @override
  void initState() {
    super.initState();
    final c = widget.cita;

    _clienteCtrl = TextEditingController(text: c?.nombreCliente ?? '');
    _establecimientoCtrl = TextEditingController(text: c?.establecimiento ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _celularCtrl = TextEditingController(text: c?.celular ?? '');
    _notasCtrl = TextEditingController(text: c?.notas ?? '');

    if (c != null) {
      _fechaSeleccionada = c.fechaHoraVisita;
      _horaSeleccionada = TimeOfDay(
        hour: c.fechaHoraVisita.hour,
        minute: c.fechaHoraVisita.minute,
      );
      _minutosAnticipacion = c.minutosAlarma;
    } else {
      final base = widget.fechaInicial ?? DateTime.now().add(const Duration(hours: 1));
      _fechaSeleccionada = base;
      _horaSeleccionada = TimeOfDay(hour: base.hour, minute: base.minute);
      _minutosAnticipacion = 60; // 1h por defecto
    }

    if (_minutosAnticipacion > 0 && !_alarmPresets.contains(_minutosAnticipacion)) {
      _isCustomAlarma = true;
      _customMinutosCtrl = TextEditingController(text: _minutosAnticipacion.toString());
    } else {
      _customMinutosCtrl = TextEditingController(text: '45');
    }
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _establecimientoCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _notasCtrl.dispose();
    _customMinutosCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: orangeAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _horaSeleccionada.hour,
          _horaSeleccionada.minute,
        );
      });
    }
  }

  Future<void> _selectHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: orangeAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
        _fechaSeleccionada = DateTime(
          _fechaSeleccionada.year,
          _fechaSeleccionada.month,
          _fechaSeleccionada.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveCita() async {
    if (!_formKey.currentState!.validate()) return;

    int minutosFinal = _minutosAnticipacion;
    if (_isCustomAlarma) {
      minutosFinal = int.tryParse(_customMinutosCtrl.text.trim()) ?? 30;
    }

    final fechaCompleta = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );

    final nuevaCita = Cita(
      id: widget.cita?.id,
      nombreCliente: _clienteCtrl.text.trim(),
      establecimiento: _establecimientoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      celular: _celularCtrl.text.trim(),
      fechaHoraVisita: fechaCompleta,
      minutosAlarma: minutosFinal,
      notas: _notasCtrl.text.trim(),
      completada: widget.cita?.completada ?? false,
    );

    if (widget.cita == null) {
      await _citasRepo.createCita(nuevaCita);
    } else {
      await _citasRepo.updateCita(nuevaCita);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cita != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          esEdicion ? 'Editar Cita' : 'Nueva Visita',
          style: const TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          TextButton(
            onPressed: _saveCita,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: orangeAccent,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Sección Cliente y Lugar
            _buildSectionHeader('Datos del Cliente y Ubicación', Icons.person_pin_circle_outlined),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _clienteCtrl,
              label: 'Nombre del Cliente *',
              hint: 'Ej. Roberto Gómez',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _establecimientoCtrl,
              label: 'Establecimiento / Local (Opcional)',
              hint: 'Ej. Fábrica Sur, Taller Mecánico, Casa familiar',
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _direccionCtrl,
              label: 'Dirección de la Visita *',
              hint: 'Ej. Av. San Martín 1420',
              icon: Icons.location_on_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la dirección completa' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _celularCtrl,
              label: 'Teléfono / Celular *',
              hint: 'Ej. +54 9 11 4444-5555',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un número de contacto' : null,
            ),
            const SizedBox(height: 24),

            // Sección Fecha y Horario
            _buildSectionHeader('Fecha y Horario de la Visita', Icons.calendar_today_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFecha,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: orangeAccent, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha', style: TextStyle(fontSize: 11, color: textGray)),
                              Text(
                                Formatters.formatDate(_fechaSeleccionada),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectHora,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hora', style: TextStyle(fontSize: 11, color: textGray)),
                              Text(
                                _horaSeleccionada.format(context),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector Flexible de Alarma (Pills rápidas: 30m, 1h, 2h + personalizada)
            _buildSectionHeader('Alarma y Recordatorio Previo', Icons.alarm_outlined),
            const SizedBox(height: 8),
            const Text(
              'Selecciona con cuánta anticipación recibirás la alarma local en tu teléfono:',
              style: TextStyle(fontSize: 12, color: textGray),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAlarmPill(
                  label: '30 min',
                  selected: !_isCustomAlarma && _minutosAnticipacion == 30,
                  onTap: () {
                    setState(() {
                      _isCustomAlarma = false;
                      _minutosAnticipacion = 30;
                    });
                  },
                ),
                _buildAlarmPill(
                  label: '1 hora',
                  selected: !_isCustomAlarma && _minutosAnticipacion == 60,
                  onTap: () {
                    setState(() {
                      _isCustomAlarma = false;
                      _minutosAnticipacion = 60;
                    });
                  },
                ),
                _buildAlarmPill(
                  label: '2 horas',
                  selected: !_isCustomAlarma && _minutosAnticipacion == 120,
                  onTap: () {
                    setState(() {
                      _isCustomAlarma = false;
                      _minutosAnticipacion = 120;
                    });
                  },
                ),
                _buildAlarmPill(
                  label: 'Personalizado',
                  selected: _isCustomAlarma,
                  onTap: () {
                    setState(() {
                      _isCustomAlarma = true;
                    });
                  },
                ),
                _buildAlarmPill(
                  label: 'Sin alarma',
                  selected: !_isCustomAlarma && _minutosAnticipacion == 0,
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    setState(() {
                      _isCustomAlarma = false;
                      _minutosAnticipacion = 0;
                    });
                  },
                ),
              ],
            ),

            if (_isCustomAlarma) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: violetAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: violetAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _customMinutosCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: const InputDecoration(
                          hintText: 'Ingresa los minutos (ej. 45, 90, 180)',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Text('minutos antes', style: TextStyle(fontSize: 12, color: textGray)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Notas
            _buildSectionHeader('Notas u Observaciones', Icons.edit_note_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notasCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: textDark),
              decoration: InputDecoration(
                hintText: 'Detalles adicionales, herramientas especiales, timbre roto...',
                hintStyle: const TextStyle(color: textGray, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: orangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botón Principal
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saveCita,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  esEdicion ? 'Actualizar Cita' : 'Confirmar y Agendar Visita',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: textDark),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textGray, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: textGray, fontSize: 13),
        prefixIcon: Icon(icon, color: textGray, size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: orangeAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAlarmPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? orangeAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : borderColor,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? activeColor : textDark,
          ),
        ),
      ),
    );
  }
}
