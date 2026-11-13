class CitaModel {
  final int? id;
  final String nombreCliente;
  final String establecimiento;
  final String direccion;
  final String celular;
  final DateTime fechaHoraVisita;
  final int minutosAlarma; // Minutos antes de la cita para disparar la alarma. 0 = desactivada
  final String notas;
  final bool completada;

  CitaModel({
    this.id,
    required this.nombreCliente,
    this.establecimiento = '',
    required this.direccion,
    required this.celular,
    required this.fechaHoraVisita,
    this.minutosAlarma = 60,
    this.notas = '',
    this.completada = false,
  });

  /// Alias de compatibilidad
  int get minutosAnticipacionAlarma => minutosAlarma;

  bool get tieneAlarmaActiva => !completada && minutosAlarma > 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre_cliente': nombreCliente,
      'establecimiento': establecimiento,
      'direccion': direccion,
      'celular': celular,
      'fecha_hora_visita': fechaHoraVisita.toIso8601String(),
      'minutos_anticipacion_alarma': minutosAlarma,
      'notas': notas,
      'completada': completada ? 1 : 0,
    };
  }

  factory CitaModel.fromMap(Map<String, dynamic> map) {
    final minutos = map['minutos_alarma'] ?? map['minutos_anticipacion_alarma'] ?? 60;
    return CitaModel(
      id: map['id'] as int?,
      nombreCliente: map['nombre_cliente'] as String? ?? '',
      establecimiento: map['establecimiento'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      celular: map['celular'] as String? ?? '',
      fechaHoraVisita:
          DateTime.tryParse(map['fecha_hora_visita'] as String? ?? '') ?? DateTime.now(),
      minutosAlarma: (minutos as num).toInt(),
      notas: map['notas'] as String? ?? '',
      completada: (map['completada'] as int? ?? 0) == 1,
    );
  }

  CitaModel copyWith({
    int? id,
    String? nombreCliente,
    String? establecimiento,
    String? direccion,
    String? celular,
    DateTime? fechaHoraVisita,
    int? minutosAlarma,
    int? minutosAnticipacionAlarma,
    String? notas,
    bool? completada,
  }) {
    return CitaModel(
      id: id ?? this.id,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      establecimiento: establecimiento ?? this.establecimiento,
      direccion: direccion ?? this.direccion,
      celular: celular ?? this.celular,
      fechaHoraVisita: fechaHoraVisita ?? this.fechaHoraVisita,
      minutosAlarma: minutosAlarma ?? minutosAnticipacionAlarma ?? this.minutosAlarma,
      notas: notas ?? this.notas,
      completada: completada ?? this.completada,
    );
  }
}

/// Alias para usar Cita o CitaModel indistintamente
typedef Cita = CitaModel;
