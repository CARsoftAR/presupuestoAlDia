import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_scaffold.dart';
import 'package:presupuesto_al_dia/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/presentation/screens/perfil_screen.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/screens/presupuestos_list_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AgendaScreen(),
    PresupuestosListScreen(),
    PerfilScreen(),
  ];

  final List<String> _titles = [
    'Agenda de Visitas',
    'Presupuestos Eléctricos',
    'Mi Perfil & Cabecera PDF',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 8),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.green),
                SizedBox(width: 4),
                Text(
                  '100% Offline',
                  style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.orange.withValues(alpha: 0.25),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppColors.orange, size: 24);
                }
                return const IconThemeData(color: AppColors.textSecondary, size: 22);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  selectedIcon: Icon(Icons.request_quote_rounded),
                  label: 'Presupuestos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Mi Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

