import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización de fechas en español
  await initializeDateFormatting('es', null);

  // Inicializar servicio de notificaciones locales y alarmas
  await NotificationService.instance.init();

  runApp(const PresupuestoAlDiaApp());
}

class PresupuestoAlDiaApp extends StatelessWidget {
  const PresupuestoAlDiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presupuesto Al Día - Electricista Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavScreen(),
    );
  }
}
