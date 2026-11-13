import 'package:flutter/material.dart';

enum EstadoPresupuesto {
  borrador('BORRADOR', 'Borrador', Color(0xFF6B7280), Color(0xFFF3F4F6)),
  pendiente('PENDIENTE', 'Pendiente', Color(0xFFD97706), Color(0xFFFEF3C7)),
  emitido('EMITIDO', 'Emitido', Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  cancelado('CANCELADO', 'Cancelado', Color(0xFFDC2626), Color(0xFFFEE2E2)),
  aceptado('ACEPTADO', 'Aceptado', Color(0xFF10B981), Color(0xFFD1FAE5));

  final String clave;
  final String nombre;
  final Color colorTexto;
  final Color colorFondo;

  const EstadoPresupuesto(
    this.clave,
    this.nombre,
    this.colorTexto,
    this.colorFondo,
  );

  static EstadoPresupuesto desdeString(String? estado) {
    if (estado == null) return EstadoPresupuesto.borrador;
    final upper = estado.toUpperCase().trim();
    for (final e in EstadoPresupuesto.values) {
      if (e.clave == upper) return e;
    }
    return EstadoPresupuesto.borrador;
  }

  static Color obtenerColorTexto(String estado) {
    return desdeString(estado).colorTexto;
  }

  static Color obtenerColorFondo(String estado) {
    return desdeString(estado).colorFondo;
  }
}

