import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_container.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/presentation/screens/pdf_preview_screen.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/services/pdf_service.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/screens/presupuesto_form_screen.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/widgets/estado_badge.dart';

class PresupuestoDetailScreen extends StatefulWidget {
  final int presupuestoId;

  const PresupuestoDetailScreen({super.key, required this.presupuestoId});

  @override
  State<PresupuestoDetailScreen> createState() => _PresupuestoDetailScreenState();
}

class _PresupuestoDetailScreenState extends State<PresupuestoDetailScreen> {
  final _repo = PresupuestosRepository();
  final _perfilRepo = PerfilRepository();

  PresupuestoModel? _presupuesto;
  PerfilModel? _perfil;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await _repo.getPresupuestoById(widget.presupuestoId);
    final perf = await _perfilRepo.getPerfil();
    if (mounted) {
      setState(() {
        _presupuesto = p;
        _perfil = perf;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeEstado(String nuevoEstado) async {
    if (_presupuesto?.id == null) return;
    await _repo.updateEstado(_presupuesto!.id!, nuevoEstado);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a $nuevoEstado'),
          backgroundColor: AppColors.getEstadoColor(nuevoEstado),
        ),
      );
    }
  }

  void _showEstadoDialog() {
    if (_presupuesto == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar Estado del Presupuesto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ...PresupuestoModel.estadosValidos.map((st) {
                final isCurrent = _presupuesto!.estado == st;
                final color = AppColors.getEstadoColor(st);
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: color,
                  ),
                  title: Text(
                    st,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? color : Colors.white,
                    ),
                  ),
                  trailing: isCurrent ? Icon(Icons.check, color: color) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeEstado(st);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePresupuesto() async {
    if (_presupuesto?.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        title: const Text('¿Eliminar Presupuesto?'),
        content: Text(
            'Se borrará el presupuesto ${_presupuesto!.numeroPresupuesto} y todos sus materiales asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.estadoCancelado),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _repo.deletePresupuesto(_presupuesto!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    if (_presupuesto == null) {
      return GlassScaffold(
        appBar: AppBar(title: const Text('Presupuesto')),
        body: const Center(child: Text('Presupuesto no encontrado')),
      );
    }

    final p = _presupuesto!;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(p.numeroPresupuesto),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_rounded, color: AppColors.orange),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresupuestoFormScreen(presupuesto: p),
                ),
              );
              if (res == true) {
                _loadData();
              }
            },
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.estadoCancelado),
            onPressed: _deletePresupuesto,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner de Estado y Acciones Rápidas
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showEstadoDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          EstadoBadge(estado: p.estado, fontSize: 13),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatDate(p.fechaEmision),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botones directos de PDF y WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_perfil == null) return;
                          await PdfService.instance.shareViaWhatsApp(
                            presupuesto: p,
                            perfil: _perfil!,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_perfil == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPreviewScreen(
                                presupuesto: p,
                                perfil: _perfil!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text('Ver PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.violet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Datos del Cliente
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_pin_rounded, color: AppColors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.nombreCliente,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (p.direccion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(p.direccion, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
                if (p.celular.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 15, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(p.celular, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Validez de la oferta: ${p.validezDias} días',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tareas a realizar
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.build_circle_rounded, color: AppColors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Tareas a Realizar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      left: BorderSide(color: AppColors.orange, width: 3.5),
                    ),
                  ),
                  child: Text(
                    p.descripcionTrabajo,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Detalle de Materiales
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_bulleted_rounded, color: AppColors.violet, size: 20),
                        SizedBox(width: 8),
                        Text('Detalle de Materiales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    Text(
                      '${p.materiales.length} ítems',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...p.materiales.map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${Formatters.formatNumber(m.cantidad)} ${m.unidad}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.descripcion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                'Unit: ${Formatters.formatCurrency(m.precioUnitario)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(m.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(color: AppColors.glassBorder, height: 24),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      Formatters.formatCurrency(p.total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

