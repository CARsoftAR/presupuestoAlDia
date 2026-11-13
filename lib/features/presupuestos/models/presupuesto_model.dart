import 'material_item_model.dart';

class PresupuestoModel {
  final int? id;
  final String numeroPresupuesto;
  final String nombreCliente;
  final String direccion;
  final String celular;
  final DateTime fechaEmision;
  final int validezDias;
  final String estado; // BORRADOR, PENDIENTE, EMITIDO, CANCELADO, ACEPTADO
  final String descripcionTrabajo;
  final String cuerpoMensaje;
  final double total;
  final List<MaterialItemModel> materiales;

  static const List<String> estadosValidos = [
    'BORRADOR',
    'PENDIENTE',
    'EMITIDO',
    'CANCELADO',
    'ACEPTADO',
  ];

  PresupuestoModel({
    this.id,
    required this.numeroPresupuesto,
    required this.nombreCliente,
    required this.direccion,
    required this.celular,
    required this.fechaEmision,
    this.validezDias = 15,
    this.estado = 'BORRADOR',
    required this.descripcionTrabajo,
    this.cuerpoMensaje = '',
    required this.total,
    this.materiales = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_presupuesto': numeroPresupuesto,
      'nombre_cliente': nombreCliente,
      'direccion': direccion,
      'celular': celular,
      'fecha_emision': fechaEmision.toIso8601String(),
      'validez_dias': validezDias,
      'estado': estado,
      'descripcion_trabajo': descripcionTrabajo,
      'cuerpo_mensaje': cuerpoMensaje,
      'total': total,
    };
  }

  factory PresupuestoModel.fromMap(Map<String, dynamic> map, {List<MaterialItemModel>? materiales}) {
    return PresupuestoModel(
      id: map['id'] as int?,
      numeroPresupuesto: map['numero_presupuesto'] as String? ?? '',
      nombreCliente: map['nombre_cliente'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      celular: map['celular'] as String? ?? '',
      fechaEmision: DateTime.tryParse(map['fecha_emision'] as String? ?? '') ?? DateTime.now(),
      validezDias: map['validez_dias'] as int? ?? 15,
      estado: map['estado'] as String? ?? 'BORRADOR',
      descripcionTrabajo: map['descripcion_trabajo'] as String? ?? '',
      cuerpoMensaje: map['cuerpo_mensaje'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      materiales: materiales ?? [],
    );
  }

  PresupuestoModel copyWith({
    int? id,
    String? numeroPresupuesto,
    String? nombreCliente,
    String? direccion,
    String? celular,
    DateTime? fechaEmision,
    int? validezDias,
    String? estado,
    String? descripcionTrabajo,
    String? cuerpoMensaje,
    double? total,
    List<MaterialItemModel>? materiales,
  }) {
    return PresupuestoModel(
      id: id ?? this.id,
      numeroPresupuesto: numeroPresupuesto ?? this.numeroPresupuesto,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      direccion: direccion ?? this.direccion,
      celular: celular ?? this.celular,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      validezDias: validezDias ?? this.validezDias,
      estado: estado ?? this.estado,
      descripcionTrabajo: descripcionTrabajo ?? this.descripcionTrabajo,
      cuerpoMensaje: cuerpoMensaje ?? this.cuerpoMensaje,
      total: total ?? this.total,
      materiales: materiales ?? this.materiales,
    );
  }
}

