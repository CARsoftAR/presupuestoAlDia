import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/screens/presupuesto_form_screen.dart';

class CitaCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onToggleCompletada;
  final ValueChanged<bool> onToggleAlarma;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Paleta de colores minimalista modo claro
  static const Color orangeAccent = Color(0xFFFF6B00);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color violetAccent = Color(0xFF7C3AED);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);

  const CitaCard({
    super.key,
    required this.cita,
    required this.onToggleCompletada,
    required this.onToggleAlarma,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatAlarmaTexto(int minutos) {
    if (minutos <= 0) return 'Alarma desactivada';
    if (minutos < 60) return 'Alarma: $minutos min antes';
    if (minutos == 60) return 'Alarma: 1 hora antes';
    if (minutos % 60 == 0) return 'Alarma: ${minutos ~/ 60} horas antes';
    return 'Alarma: ${minutos ~/ 60}h ${minutos % 60}m antes';
  }

  Future<void> _abrirGoogleMaps(BuildContext context) async {
    final query = Uri.encodeComponent(cita.direccion);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir Maps: $e')),
        );
      }
    }
  }

  Future<void> _hacerLlamada(BuildContext context) async {
    final cleanPhone = cita.celular.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede iniciar la llamada')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al llamar: $e');
    }
  }

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final cleanPhone = cita.celular.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hola ${cita.nombreCliente}, te contacto de Electricista Pro para coordinar la visita técnica agendada para el ${Formatters.formatDateTime(cita.fechaHoraVisita)}.',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$msg');
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPasada = cita.fechaHoraVisita.isBefore(DateTime.now());
    final bool alarmaPrendida = cita.minutosAlarma > 0 && !cita.completada;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cita.completada
              ? greenAccent.withValues(alpha: 0.4)
              : borderColor,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Hora, Badge de estado y Menú de opciones
            Row(
              children: [
                // Hora destacada
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cita.completada
                        ? greenAccent.withValues(alpha: 0.1)
                        : (esPasada
                            ? const Color(0xFFFEE2E2)
                            : orangeAccent.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: cita.completada
                            ? greenAccent
                            : (esPasada ? const Color(0xFFDC2626) : orangeAccent),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatTime(cita.fechaHoraVisita),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: cita.completada
                              ? greenAccent
                              : (esPasada ? const Color(0xFFDC2626) : orangeAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  Formatters.formatDate(cita.fechaHoraVisita),
                  style: const TextStyle(fontSize: 12, color: textGray),
                ),
                const Spacer(),
                // Checkbox / switch de completada
                InkWell(
                  onTap: onToggleCompletada,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          cita.completada
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: cita.completada ? greenAccent : textGray,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cita.completada ? 'Realizada' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cita.completada ? greenAccent : textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Menú desplegable minimalista
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: textGray, size: 20),
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    } else if (val == 'presupuesto') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresupuestoFormScreen(
                            clientePrellenado: cita.nombreCliente,
                            direccionPrellenada: cita.direccion,
                            celularPrellenado: cita.celular,
                            descripcionPrellenada: cita.notas.isNotEmpty
                                ? 'Visita en ${cita.establecimiento.isNotEmpty ? cita.establecimiento : cita.nombreCliente}: ${cita.notas}'
                                : 'Instalación y revisión técnica en ${cita.direccion}',
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'presupuesto',
                      child: Row(
                        children: [
                          Icon(Icons.request_quote_outlined, color: greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Generar Presupuesto', style: TextStyle(color: textDark, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: orangeAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Editar Cita', style: TextStyle(color: textDark, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nombre del Cliente
            Text(
              cita.nombreCliente,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cita.completada ? textGray : textDark,
                decoration: cita.completada ? TextDecoration.lineThrough : null,
              ),
            ),

            // Establecimiento (si existe)
            if (cita.establecimiento.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 14, color: violetAccent),
                  const SizedBox(width: 4),
                  Text(
                    cita.establecimiento,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),

            // Dirección con enlace a Google Maps
            InkWell(
              onTap: () => _abrirGoogleMaps(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: orangeAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cita.direccion,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textDark,
                          decoration: TextDecoration.underline,
                          decorationColor: borderColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_outlined, size: 12, color: orangeAccent),
                          SizedBox(width: 3),
                          Text(
                            'Maps',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (cita.notas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  cita.notas,
                  style: const TextStyle(fontSize: 12, color: textGray, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: borderColor, height: 1),
            const SizedBox(height: 10),

            // Fila inferior: Alarma con Switch rápido y Botones Limpios de Llamar/WhatsApp
            Row(
              children: [
                // Estado de Alarma con Switch rápido
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        alarmaPrendida ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                        size: 16,
                        color: alarmaPrendida ? orangeAccent : textGray,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatAlarmaTexto(cita.minutosAlarma),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: alarmaPrendida ? FontWeight.w600 : FontWeight.normal,
                            color: alarmaPrendida ? orangeAccent : textGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: alarmaPrendida,
                          activeThumbColor: orangeAccent,
                          onChanged: cita.completada ? null : onToggleAlarma,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Botón Limpio Llamar
                OutlinedButton.icon(
                  onPressed: () => _hacerLlamada(context),
                  icon: const Icon(Icons.phone_outlined, size: 14),
                  label: const Text('Llamar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),

                // Botón Limpio WhatsApp
                ElevatedButton.icon(
                  onPressed: () => _abrirWhatsApp(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
