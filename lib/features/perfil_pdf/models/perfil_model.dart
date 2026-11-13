class PerfilModel {
  final int id;
  final String nombreEmpresa;
  final String nombreElectricista;
  final String matricula;
  final String direccion;
  final String telefono;
  final String email;
  final String? rutaImagenCabecera;
  final String cuerpoMensajeDefault;
  final String piePagina;

  PerfilModel({
    this.id = 1,
    required this.nombreEmpresa,
    required this.nombreElectricista,
    required this.matricula,
    required this.direccion,
    required this.telefono,
    required this.email,
    this.rutaImagenCabecera,
    required this.cuerpoMensajeDefault,
    required this.piePagina,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_empresa': nombreEmpresa,
      'nombre_electricista': nombreElectricista,
      'matricula': matricula,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'ruta_imagen_cabecera': rutaImagenCabecera,
      'cuerpo_mensaje_default': cuerpoMensajeDefault,
      'pie_pagina': piePagina,
    };
  }

  factory PerfilModel.fromMap(Map<String, dynamic> map) {
    return PerfilModel(
      id: map['id'] as int? ?? 1,
      nombreEmpresa: map['nombre_empresa'] as String? ?? '',
      nombreElectricista: map['nombre_electricista'] as String? ?? '',
      matricula: map['matricula'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rutaImagenCabecera: map['ruta_imagen_cabecera'] as String?,
      cuerpoMensajeDefault: map['cuerpo_mensaje_default'] as String? ?? '',
      piePagina: map['pie_pagina'] as String? ?? '',
    );
  }

  PerfilModel copyWith({
    int? id,
    String? nombreEmpresa,
    String? nombreElectricista,
    String? matricula,
    String? direccion,
    String? telefono,
    String? email,
    String? rutaImagenCabecera,
    String? cuerpoMensajeDefault,
    String? piePagina,
  }) {
    return PerfilModel(
      id: id ?? this.id,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      nombreElectricista: nombreElectricista ?? this.nombreElectricista,
      matricula: matricula ?? this.matricula,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      rutaImagenCabecera: rutaImagenCabecera ?? this.rutaImagenCabecera,
      cuerpoMensajeDefault: cuerpoMensajeDefault ?? this.cuerpoMensajeDefault,
      piePagina: piePagina ?? this.piePagina,
    );
  }
}

