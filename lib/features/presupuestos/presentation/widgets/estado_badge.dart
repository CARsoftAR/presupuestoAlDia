import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';

class EstadoBadge extends StatelessWidget {
  final String estado;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const EstadoBadge({
    super.key,
    required this.estado,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getEstadoColor(estado);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

