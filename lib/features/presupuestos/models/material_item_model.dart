class MaterialItemModel {
  final int? id;
  final int? presupuestoId;
  final String descripcion;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double subtotal;

  MaterialItemModel({
    this.id,
    this.presupuestoId,
    required this.descripcion,
    required this.cantidad,
    this.unidad = 'un.',
    required this.precioUnitario,
    double? subtotal,
  }) : subtotal = subtotal ?? (cantidad * precioUnitario);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (presupuestoId != null) 'presupuesto_id': presupuestoId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'unidad': unidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory MaterialItemModel.fromMap(Map<String, dynamic> map) {
    return MaterialItemModel(
      id: map['id'] as int?,
      presupuestoId: map['presupuesto_id'] as int?,
      descripcion: map['descripcion'] as String? ?? '',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 1.0,
      unidad: map['unidad'] as String? ?? 'un.',
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  MaterialItemModel copyWith({
    int? id,
    int? presupuestoId,
    String? descripcion,
    double? cantidad,
    String? unidad,
    double? precioUnitario,
    double? subtotal,
  }) {
    return MaterialItemModel(
      id: id ?? this.id,
      presupuestoId: presupuestoId ?? this.presupuestoId,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? ((cantidad ?? this.cantidad) * (precioUnitario ?? this.precioUnitario)),
    );
  }
}

