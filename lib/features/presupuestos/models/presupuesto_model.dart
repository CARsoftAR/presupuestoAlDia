import 'presupuesto_estado.dart';
import 'presupuesto_item_model.dart';

class PresupuestoModel {
  final int? id;
  final String numeroPresupuesto;
  final int? clienteId;
  final String nombreCliente;
  final String direccion;
  final String celular;
  final DateTime fechaEmision;
  final int validezDias;
  final String estado; // BORRADOR, PENDIENTE, EMITIDO, CANCELADO, ACEPTADO
  final String descripcionTrabajo;
  final String cuerpoMensaje;
  final double total;
  final List<PresupuestoItemModel> items;

  // Lista de estados requeridos
  static const List<String> estadosValidos = [
    'BORRADOR',
    'PENDIENTE',
    'EMITIDO',
    'ACEPTADO',
    'CANCELADO',
  ];

  PresupuestoModel({
    this.id,
    required this.numeroPresupuesto,
    this.clienteId,
    required this.nombreCliente,
    required this.direccion,
    required this.celular,
    required this.fechaEmision,
    this.validezDias = 15,
    this.estado = 'BORRADOR',
    required this.descripcionTrabajo,
    this.cuerpoMensaje = '',
    required this.total,
    this.items = const [],
  });

  /// Alias de propiedades para máxima flexibilidad
  String get numero => numeroPresupuesto;
  DateTime get fecha => fechaEmision;
  List<PresupuestoItemModel> get materiales => items;

  EstadoPresupuesto get estadoEnum => EstadoPresupuesto.desdeString(estado);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_presupuesto': numeroPresupuesto,
      'nombre_cliente': nombreCliente,
      'direccion': direccion,
      'celular': celular,
      'fecha_emision': fechaEmision.toIso8601String(),
      'validez_dias': validezDias,
      'estado': estado.toUpperCase().trim(),
      'descripcion_trabajo': descripcionTrabajo,
      'cuerpo_mensaje': cuerpoMensaje,
      'total': total,
    };
  }

  factory PresupuestoModel.fromMap(
    Map<String, dynamic> map, {
    List<PresupuestoItemModel>? items,
    List<PresupuestoItemModel>? materiales,
  }) {
    final numPresupuesto = map['numero_presupuesto'] ?? map['numero'] ?? '';
    final fechaRaw = map['fecha_emision'] ?? map['fecha'] ?? '';

    return PresupuestoModel(
      id: map['id'] as int?,
      numeroPresupuesto: numPresupuesto.toString(),
      clienteId: map['cliente_id'] as int?,
      nombreCliente: map['nombre_cliente'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      celular: map['celular'] as String? ?? '',
      fechaEmision: DateTime.tryParse(fechaRaw.toString()) ?? DateTime.now(),
      validezDias: map['validez_dias'] as int? ?? 15,
      estado: map['estado'] as String? ?? 'BORRADOR',
      descripcionTrabajo: map['descripcion_trabajo'] as String? ?? '',
      cuerpoMensaje: map['cuerpo_mensaje'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      items: items ?? materiales ?? [],
    );
  }

  PresupuestoModel copyWith({
    int? id,
    String? numeroPresupuesto,
    int? clienteId,
    String? nombreCliente,
    String? direccion,
    String? celular,
    DateTime? fechaEmision,
    int? validezDias,
    String? estado,
    String? descripcionTrabajo,
    String? cuerpoMensaje,
    double? total,
    List<PresupuestoItemModel>? items,
  }) {
    return PresupuestoModel(
      id: id ?? this.id,
      numeroPresupuesto: numeroPresupuesto ?? this.numeroPresupuesto,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      direccion: direccion ?? this.direccion,
      celular: celular ?? this.celular,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      validezDias: validezDias ?? this.validezDias,
      estado: estado ?? this.estado,
      descripcionTrabajo: descripcionTrabajo ?? this.descripcionTrabajo,
      cuerpoMensaje: cuerpoMensaje ?? this.cuerpoMensaje,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }
}

/// Alias para uso indistinto
typedef Presupuesto = PresupuestoModel;
