import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_estado.dart';

class EstadoBadge extends StatelessWidget {
  final String estado;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const EstadoBadge({
    super.key,
    required this.estado,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final estadoEnum = EstadoPresupuesto.desdeString(estado);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: estadoEnum.colorFondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: estadoEnum.colorTexto.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: estadoEnum.colorTexto,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            estadoEnum.nombre.toUpperCase(),
            style: TextStyle(
              color: estadoEnum.colorTexto,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
