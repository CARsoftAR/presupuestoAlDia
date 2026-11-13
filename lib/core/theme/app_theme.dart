import 'package:flutter/material.dart';

class AppColors {
  // Paleta principal requerida
  static const Color orange = Color(0xFFFF6B00);
  static const Color green = Color(0xFF00D084);
  static const Color violet = Color(0xFF7B2CBF);

  // Colores de soporte y fondo
  static const Color bgDark = Color(0xFF0F0C20);
  static const Color bgDarkSecondary = Color(0xFF181333);
  static const Color bgCard = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFFADB5BD);
  static const Color textMuted = Color(0xFF6C757D);

  // Estados de Presupuesto
  static const Color estadoBorrador = Color(0xFF9E9E9E);
  static const Color estadoPendiente = Color(0xFFFF9F1C);
  static const Color estadoEmitido = Color(0xFF2EC4B6);
  static const Color estadoCancelado = Color(0xFFE71D36);
  static const Color estadoAceptado = Color(0xFF00D084);

  static Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'BORRADOR':
        return estadoBorrador;
      case 'PENDIENTE':
        return estadoPendiente;
      case 'EMITIDO':
        return estadoEmitido;
      case 'CANCELADO':
        return estadoCancelado;
      case 'ACEPTADO':
        return estadoAceptado;
      default:
        return textSecondary;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.orange,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.green,
        tertiary: AppColors.violet,
        surface: AppColors.bgDarkSecondary,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.estadoCancelado, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.orange.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}

