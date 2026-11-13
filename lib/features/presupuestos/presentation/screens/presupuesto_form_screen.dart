import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_container.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/material_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/widgets/estado_badge.dart';

class _MaterialInputController {
  final TextEditingController descripcionCtrl;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;
  String unidad;

  _MaterialInputController({
    String descripcion = '',
    double cantidad = 1.0,
    double precioUnitario = 0.0,
    this.unidad = 'un.',
  })  : descripcionCtrl = TextEditingController(text: descripcion),
        cantidadCtrl = TextEditingController(
            text: cantidad == cantidad.roundToDouble()
                ? cantidad.toInt().toString()
                : cantidad.toString()),
        precioCtrl = TextEditingController(
            text: precioUnitario > 0
                ? (precioUnitario == precioUnitario.roundToDouble()
                    ? precioUnitario.toInt().toString()
                    : precioUnitario.toString())
                : '');

  double get cantidad => double.tryParse(cantidadCtrl.text.replaceAll(',', '.')) ?? 0.0;
  double get precioUnitario => double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0.0;
  double get subtotal => cantidad * precioUnitario;

  void dispose() {
    descripcionCtrl.dispose();
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}

class PresupuestoFormScreen extends StatefulWidget {
  final PresupuestoModel? presupuesto;
  final String? clientePrellenado;
  final String? direccionPrellenada;
  final String? celularPrellenado;
  final String? descripcionPrellenada;

  const PresupuestoFormScreen({
    super.key,
    this.presupuesto,
    this.clientePrellenado,
    this.direccionPrellenada,
    this.celularPrellenado,
    this.descripcionPrellenada,
  });

  @override
  State<PresupuestoFormScreen> createState() => _PresupuestoFormScreenState();
}

class _PresupuestoFormScreenState extends State<PresupuestoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PresupuestosRepository();
  final _perfilRepo = PerfilRepository();

  late TextEditingController _numeroCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _celularCtrl;
  late TextEditingController _validezCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _cuerpoMensajeCtrl;

  String _estado = 'BORRADOR';
  DateTime _fechaEmision = DateTime.now();
  final List<_MaterialInputController> _materiales = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.presupuesto;

    _numeroCtrl = TextEditingController(text: p?.numeroPresupuesto ?? '');
    _clienteCtrl = TextEditingController(text: p?.nombreCliente ?? widget.clientePrellenado ?? '');
    _direccionCtrl = TextEditingController(text: p?.direccion ?? widget.direccionPrellenada ?? '');
    _celularCtrl = TextEditingController(text: p?.celular ?? widget.celularPrellenado ?? '');
    _validezCtrl = TextEditingController(text: (p?.validezDias ?? 15).toString());
    _descripcionCtrl = TextEditingController(text: p?.descripcionTrabajo ?? widget.descripcionPrellenada ?? '');
    _cuerpoMensajeCtrl = TextEditingController(text: p?.cuerpoMensaje ?? '');

    if (p != null) {
      _estado = p.estado;
      _fechaEmision = p.fechaEmision;
      for (final m in p.materiales) {
        _materiales.add(_MaterialInputController(
          descripcion: m.descripcion,
          cantidad: m.cantidad,
          precioUnitario: m.precioUnitario,
          unidad: m.unidad,
        ));
      }
      _isLoading = false;
    } else {
      _initNewPresupuesto();
    }
  }

  Future<void> _initNewPresupuesto() async {
    final nextNum = await _repo.generateNextNumeroPresupuesto();
    final perfil = await _perfilRepo.getPerfil();

    if (_cuerpoMensajeCtrl.text.isEmpty) {
      _cuerpoMensajeCtrl.text = perfil.cuerpoMensajeDefault;
    }

    _numeroCtrl.text = nextNum;

    // Agregar 1 fila inicial por defecto para agilidad
    _addMaterialRow(
      descripcion: 'Mano de obra especializada e instalación',
      cantidad: 1,
      precio: 0,
      unidad: 'global',
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _addMaterialRow({
    String descripcion = '',
    double cantidad = 1,
    double precio = 0,
    String unidad = 'un.',
  }) {
    final controller = _MaterialInputController(
      descripcion: descripcion,
      cantidad: cantidad,
      precioUnitario: precio,
      unidad: unidad,
    );
    setState(() {
      _materiales.add(controller);
    });
  }

  void _removeMaterialRow(int index) {
    if (_materiales.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe existir al menos un ítem o concepto de mano de obra'),
          backgroundColor: AppColors.estadoCancelado,
        ),
      );
      return;
    }
    setState(() {
      final removed = _materiales.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalCalculado {
    double sum = 0.0;
    for (final item in _materiales) {
      sum += item.subtotal;
    }
    return sum;
  }

  Future<void> _savePresupuesto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_materiales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un material o ítem'),
          backgroundColor: AppColors.estadoCancelado,
        ),
      );
      return;
    }

    // Convertir a modelos de material
    final List<MaterialItemModel> listaMateriales = [];
    for (final matCtrl in _materiales) {
      final desc = matCtrl.descripcionCtrl.text.trim();
      if (desc.isEmpty) continue;

      listaMateriales.add(MaterialItemModel(
        descripcion: desc,
        cantidad: matCtrl.cantidad <= 0 ? 1 : matCtrl.cantidad,
        unidad: matCtrl.unidad,
        precioUnitario: matCtrl.precioUnitario,
        subtotal: matCtrl.subtotal,
      ));
    }

    if (listaMateriales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa la descripción de al menos un ítem'),
          backgroundColor: AppColors.estadoCancelado,
        ),
      );
      return;
    }

    final validez = int.tryParse(_validezCtrl.text.trim()) ?? 15;

    final nuevoPresupuesto = PresupuestoModel(
      id: widget.presupuesto?.id,
      numeroPresupuesto: _numeroCtrl.text.trim(),
      nombreCliente: _clienteCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      celular: _celularCtrl.text.trim(),
      fechaEmision: _fechaEmision,
      validezDias: validez,
      estado: _estado,
      descripcionTrabajo: _descripcionCtrl.text.trim(),
      cuerpoMensaje: _cuerpoMensajeCtrl.text.trim(),
      total: _totalCalculado,
      materiales: listaMateriales,
    );

    if (widget.presupuesto == null) {
      await _repo.createPresupuesto(nuevoPresupuesto);
    } else {
      await _repo.updatePresupuesto(nuevoPresupuesto);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _clienteCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _validezCtrl.dispose();
    _descripcionCtrl.dispose();
    _cuerpoMensajeCtrl.dispose();
    for (final m in _materiales) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    final esEdicion = widget.presupuesto != null;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar ${_numeroCtrl.text}' : 'Nuevo Presupuesto'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.check_rounded, color: AppColors.green, size: 28),
            onPressed: _savePresupuesto,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Cabecera: Número y Selector Visual de Estado
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('N° Presupuesto', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            _numeroCtrl.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      EstadoBadge(estado: _estado, fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Estado del Presupuesto:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  // Selector visual interactivo de estado con colores distintivos
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PresupuestoModel.estadosValidos.map((st) {
                      final isSelected = _estado == st;
                      final color = AppColors.getEstadoColor(st);
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.3),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(
                          color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? color : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _estado = st);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Datos del Cliente
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_rounded, color: AppColors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Datos del Cliente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _clienteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y Apellido del Cliente *',
                      hintText: 'Ej. Juan Pérez',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de la Instalación',
                      hintText: 'Ej. Calle San Martín 450',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: _celularCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Celular / WhatsApp',
                            hintText: 'Ej. +54 9 11 9999-8888',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _validezCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Validez (días)',
                            hintText: '15',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo amplio: Qué hay que hacer
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.handyman_rounded, color: AppColors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '¿Qué hay que hacer? (Descripción de Trabajo) *',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej. CABLEAR TODO EL TECHO DE LA PLANTA ALTA, cambio de llaves térmicas y disyuntor, instalación de 6 artefactos de iluminación LED embutidos...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Indica los trabajos a realizar'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista dinámica de Materiales con cálculo automático
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppColors.violet, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Materiales y Mano de Obra',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Agregar Ítem',
                        icon: const Icon(Icons.add_circle, color: AppColors.green, size: 28),
                        onPressed: () => _addMaterialRow(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingresa cantidad, descripción y precio unitario. El subtotal y total se actualizan en tiempo real.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Filas dinámicas
                  ..._materiales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final itemCtrl = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.violet.withValues(alpha: 0.4),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: itemCtrl.descripcionCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Cable unipolar 2.5mm, 50 Tarugos...',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.estadoCancelado, size: 20),
                                onPressed: () => _removeMaterialRow(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Cantidad
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: itemCtrl.cantidadCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Cant.',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Unidad
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: itemCtrl.unidad,
                                  decoration: InputDecoration(
                                    labelText: 'Unid.',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  dropdownColor: AppColors.bgDarkSecondary,
                                  items: const [
                                    DropdownMenuItem(value: 'un.', child: Text('un.')),
                                    DropdownMenuItem(value: 'mts.', child: Text('mts.')),
                                    DropdownMenuItem(value: 'kg.', child: Text('kg.')),
                                    DropdownMenuItem(value: 'rollo', child: Text('rollo')),
                                    DropdownMenuItem(value: 'global', child: Text('global')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => itemCtrl.unidad = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Precio Unitario
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: itemCtrl.precioCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'P. Unit.',
                                    prefixText: '\$ ',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Subtotal calculado
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  Text(
                                    Formatters.formatCurrency(itemCtrl.subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addMaterialRow(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar otro ítem o material'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.violet,
                      side: const BorderSide(color: AppColors.violet),
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.glassBorder),
                  const SizedBox(height: 8),

                  // TOTAL GENERAL CALCULADO EN TIEMPO REAL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange.withValues(alpha: 0.25),
                          AppColors.green.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                            Text('Cálculo automático en tiempo real', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(_totalCalculado),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mensaje Adicional Opcional
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Mensaje para el Cliente (PDF)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cuerpoMensajeCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Texto introductorio en el PDF...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón Principal Guardar
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _savePresupuesto,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  esEdicion ? 'Actualizar Presupuesto' : 'Crear Presupuesto',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  elevation: 6,
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

