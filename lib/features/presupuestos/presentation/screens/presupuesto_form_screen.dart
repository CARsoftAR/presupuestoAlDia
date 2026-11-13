import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/presentation/screens/pdf_preview_screen.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_estado.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';

class _ItemInputRow {
  final TextEditingController descripcionCtrl;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;
  String unidad;

  _ItemInputRow({
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
  final List<_ItemInputRow> _filasItems = [];
  bool _isLoading = true;

  // Paleta minimalista modo claro
  static const Color orangeAccent = Color(0xFFFF6B00);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);

  final List<String> _estadosVisuales = [
    'BORRADOR',
    'PENDIENTE',
    'EMITIDO',
    'ACEPTADO',
    'CANCELADO',
  ];

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
      for (final item in p.items) {
        _filasItems.add(_ItemInputRow(
          descripcion: item.descripcion,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          unidad: item.unidad,
        ));
      }
      _isLoading = false;
    } else {
      _inicializarNuevo();
    }
  }

  Future<void> _inicializarNuevo() async {
    final nextNum = await _repo.generateNextNumeroPresupuesto();
    final perfil = await _perfilRepo.getPerfil();

    if (_cuerpoMensajeCtrl.text.isEmpty) {
      _cuerpoMensajeCtrl.text = perfil.cuerpoMensajeDefault;
    }

    _numeroCtrl.text = nextNum;

    // Fila inicial por defecto
    _agregarFila(
      descripcion: 'Mano de obra especializada e instalación',
      cantidad: 1,
      precio: 0,
      unidad: 'global',
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _agregarFila({
    String descripcion = '',
    double cantidad = 1,
    double precio = 0,
    String unidad = 'un.',
  }) {
    setState(() {
      _filasItems.add(_ItemInputRow(
        descripcion: descripcion,
        cantidad: cantidad,
        precioUnitario: precio,
        unidad: unidad,
      ));
    });
  }

  void _eliminarFila(int index) {
    if (_filasItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe existir al menos un ítem o trabajo'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      final removed = _filasItems.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalCalculado {
    double sum = 0.0;
    for (final fila in _filasItems) {
      sum += fila.subtotal;
    }
    return sum;
  }

  PresupuestoModel _construirPresupuestoModelo() {
    final List<PresupuestoItemModel> listaItems = [];
    for (final fila in _filasItems) {
      final desc = fila.descripcionCtrl.text.trim();
      if (desc.isEmpty) continue;

      listaItems.add(PresupuestoItemModel(
        descripcion: desc,
        cantidad: fila.cantidad <= 0 ? 1 : fila.cantidad,
        unidad: fila.unidad,
        precioUnitario: fila.precioUnitario,
        subtotal: fila.subtotal,
      ));
    }

    final validez = int.tryParse(_validezCtrl.text.trim()) ?? 15;

    return PresupuestoModel(
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
      items: listaItems,
    );
  }

  Future<bool> _guardarPresupuesto() async {
    if (!_formKey.currentState!.validate()) return false;

    final modelo = _construirPresupuestoModelo();

    if (modelo.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ítem o material con su descripción'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return false;
    }

    if (widget.presupuesto == null) {
      await _repo.createPresupuesto(modelo);
    } else {
      await _repo.updatePresupuesto(modelo);
    }

    return true;
  }

  Future<void> _abrirVistaPreviaPdfOWha() async {
    if (!_formKey.currentState!.validate()) return;
    final modelo = _construirPresupuestoModelo();
    if (modelo.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ítem para visualizar el presupuesto'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final perfil = await _perfilRepo.getPerfil();
    if (!mounted) return;

    // Abrir pantalla de previsualización con botón de compartir por WhatsApp
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          presupuesto: modelo,
          perfil: perfil,
        ),
      ),
    );
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
    for (final f in _filasItems) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: orangeAccent)),
      );
    }

    final esEdicion = widget.presupuesto != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          esEdicion ? 'Editar ${_numeroCtrl.text}' : 'Nuevo Presupuesto',
          style: const TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 120),
          children: [
            // 1. Selector Visual de Estado en la parte superior
            _buildSectionTitle('Estado del Presupuesto', Icons.flag_outlined),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _estadosVisuales.map((st) {
                  final isSelected = _estado == st;
                  final estadoEnum = EstadoPresupuesto.desdeString(st);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _estado = st),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? estadoEnum.colorFondo : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? estadoEnum.colorTexto : borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isSelected ? estadoEnum.colorTexto : textGray,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              estadoEnum.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? estadoEnum.colorTexto : textDark,
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
            const SizedBox(height: 20),

            // 2. Campos Esenciales del Cliente
            _buildSectionTitle('Datos del Cliente y Obra', Icons.person_outline),
            const SizedBox(height: 10),
            _buildInputText(
              controller: _clienteCtrl,
              label: 'Nombre del Cliente *',
              hint: 'Ej. Juan Morales',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
            ),
            const SizedBox(height: 10),
            _buildInputText(
              controller: _direccionCtrl,
              label: 'Dirección de la Obra / Instalación',
              hint: 'Ej. Av. Libertador 2200, Piso 3',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _buildInputText(
                    controller: _celularCtrl,
                    label: 'Celular / WhatsApp',
                    hint: 'Ej. +54 9 11 3333-4444',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: _buildInputText(
                    controller: _validezCtrl,
                    label: 'Validez (días)',
                    hint: '15',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Sección "Qué hay que hacer"
            _buildSectionTitle('¿Qué hay que hacer? (Descripción del Trabajo) *', Icons.handyman_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 13, color: textDark),
              decoration: InputDecoration(
                hintText: 'Ej. CABLEAR TODO EL TECHO, reemplazo de térmicas y disyuntor en tablero principal, colocación de 8 artefactos LED...',
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
                  borderSide: const BorderSide(color: orangeAccent, width: 1.5),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica los trabajos a realizar' : null,
            ),
            const SizedBox(height: 22),

            // 4. Sección "Materiales y Trabajos"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Materiales y Trabajos', Icons.format_list_bulleted_rounded),
                TextButton.icon(
                  onPressed: () => _agregarFila(),
                  icon: const Icon(Icons.add, size: 16, color: orangeAccent),
                  label: const Text(
                    'Agregar Ítem',
                    style: TextStyle(color: orangeAccent, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: orangeAccent.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filas dinámicas de materiales y mano de obra
            ..._filasItems.asMap().entries.map((entry) {
              final index = entry.key;
              final fila = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Fila 1: N° y Descripción
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: fila.descripcionCtrl,
                            style: const TextStyle(fontSize: 13, color: textDark),
                            decoration: InputDecoration(
                              hintText: 'Descripción (ej. Cable 4mm, 50 Tarugos...)',
                              hintStyle: const TextStyle(color: textGray, fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: orangeAccent),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 18),
                          tooltip: 'Eliminar ítem',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _eliminarFila(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fila 2: Cantidad, Unidad, Precio Unitario y Subtotal automático
                    Row(
                      children: [
                        // Cantidad
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: fila.cantidadCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 12, color: textDark),
                            decoration: InputDecoration(
                              labelText: 'Cant.',
                              labelStyle: const TextStyle(fontSize: 11, color: textGray),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Unidad
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: fila.unidad,
                            style: const TextStyle(fontSize: 12, color: textDark),
                            decoration: InputDecoration(
                              labelText: 'Unid.',
                              labelStyle: const TextStyle(fontSize: 11, color: textGray),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                            ),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'un.', child: Text('un.')),
                              DropdownMenuItem(value: 'mts.', child: Text('mts.')),
                              DropdownMenuItem(value: 'kg.', child: Text('kg.')),
                              DropdownMenuItem(value: 'rollo', child: Text('rollo')),
                              DropdownMenuItem(value: 'global', child: Text('global')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => fila.unidad = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Precio Unitario
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: fila.precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 12, color: textDark),
                            decoration: InputDecoration(
                              labelText: 'P. Unitario',
                              prefixText: '\$ ',
                              labelStyle: const TextStyle(fontSize: 11, color: textGray),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Subtotal automático
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 10, color: textGray)),
                            Text(
                              Formatters.formatCurrency(fila.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _agregarFila(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Agregar otro ítem o material'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),

      // 5. Barra Inferior Fija Blanca con Total General y Acciones
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderColor, width: 1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila de Total General
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL GENERAL:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(_totalCalculado),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Botones de acción: Guardar y Vista Previa PDF / WhatsApp
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await _guardarPresupuesto();
                        if (!context.mounted) return;
                        if (ok) Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Guardar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: _abrirVistaPreviaPdfOWha,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Vista Previa PDF / WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInputText({
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
        labelStyle: const TextStyle(color: textGray, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: textGray, fontSize: 12),
        prefixIcon: Icon(icon, color: textGray, size: 16),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}
