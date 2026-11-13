import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/presentation/screens/pdf_preview_screen.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/services/pdf_service.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_estado.dart';
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
      final estadoEnum = EstadoPresupuesto.desdeString(nuevoEstado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${estadoEnum.nombre}'),
          backgroundColor: estadoEnum.colorTexto,
        ),
      );
    }
  }

  void _showEstadoDialog() {
    if (_presupuesto == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cambiar Estado del Presupuesto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark),
                ),
                const SizedBox(height: 12),
                ...PresupuestoModel.estadosValidos.map((st) {
                  final isCurrent = _presupuesto!.estado == st;
                  final estadoEnum = EstadoPresupuesto.desdeString(st);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 6,
                      backgroundColor: estadoEnum.colorTexto,
                    ),
                    title: Text(
                      estadoEnum.nombre,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? estadoEnum.colorTexto : textDark,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCurrent ? Icon(Icons.check, color: estadoEnum.colorTexto, size: 20) : null,
                    onTap: () {
                      Navigator.pop(context);
                      _changeEstado(st);
                    },
                  );
                }),
              ],
            ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('¿Eliminar Presupuesto?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará ${_presupuesto!.numeroPresupuesto} y todos sus ítems asociados de forma permanente.',
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
      await _repo.deletePresupuesto(_presupuesto!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: orangeAccent)),
      );
    }

    if (_presupuesto == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Presupuesto')),
        body: const Center(child: Text('Presupuesto no encontrado')),
      );
    }

    final p = _presupuesto!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          p.numeroPresupuesto,
          style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, color: textDark, size: 20),
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
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            onPressed: _deletePresupuesto,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Banner de Estado y Botones de Acción
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showEstadoDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          EstadoBadge(estado: p.estado, fontSize: 12),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: textGray, size: 18),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatDate(p.fechaEmision),
                      style: const TextStyle(color: textGray, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Enviar WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('Ver PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Datos del Cliente
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: orangeAccent),
                    SizedBox(width: 6),
                    Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textDark)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.nombreCliente,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark),
                ),
                if (p.direccion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.direccion, style: const TextStyle(fontSize: 13, color: textGray)),
                ],
                if (p.celular.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Cel: ${p.celular}', style: const TextStyle(fontSize: 13, color: textGray)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tareas a realizar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handyman_outlined, size: 16, color: greenAccent),
                    SizedBox(width: 6),
                    Text('Tareas a Realizar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textDark)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.descripcionTrabajo,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lista de Materiales e Ítems
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_bulleted_rounded, size: 16, color: violetAccent),
                        SizedBox(width: 6),
                        Text('Materiales y Trabajos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textDark)),
                      ],
                    ),
                    Text(
                      '${p.items.length} ${p.items.length == 1 ? "ítem" : "ítems"}',
                      style: const TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...p.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${Formatters.formatNumber(item.cantidad)} ${item.unidad}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.descripcion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                              Text(
                                'Unit: ${Formatters.formatCurrency(item.precioUnitario)}',
                                style: const TextStyle(fontSize: 11, color: textGray),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textDark),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(color: borderColor, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textDark),
                    ),
                    Text(
                      Formatters.formatCurrency(p.total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: greenAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
