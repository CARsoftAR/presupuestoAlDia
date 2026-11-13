import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_container.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/services/pdf_service.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/screens/presupuesto_detail_screen.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/screens/presupuesto_form_screen.dart';
import 'package:presupuesto_al_dia/features/presupuestos/presentation/widgets/estado_badge.dart';

class PresupuestosListScreen extends StatefulWidget {
  const PresupuestosListScreen({super.key});

  @override
  State<PresupuestosListScreen> createState() => _PresupuestosListScreenState();
}

class _PresupuestosListScreenState extends State<PresupuestosListScreen> {
  final _repo = PresupuestosRepository();
  final _perfilRepo = PerfilRepository();

  List<PresupuestoModel> _presupuestos = [];
  PerfilModel? _perfil;
  bool _isLoading = true;
  String _filtroEstado = 'TODOS';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _repo.getAllPresupuestos(
      estado: _filtroEstado == 'TODOS' ? null : _filtroEstado,
    );
    final perf = await _perfilRepo.getPerfil();
    if (mounted) {
      setState(() {
        _presupuestos = list;
        _perfil = perf;
        _isLoading = false;
      });
    }
  }

  List<PresupuestoModel> get _presupuestosFiltrados {
    if (_searchQuery.isEmpty) return _presupuestos;
    final q = _searchQuery.toLowerCase();
    return _presupuestos.where((p) {
      return p.nombreCliente.toLowerCase().contains(q) ||
          p.numeroPresupuesto.toLowerCase().contains(q) ||
          p.descripcionTrabajo.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openDetail(PresupuestoModel p) async {
    if (p.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresupuestoDetailScreen(presupuestoId: p.id!),
      ),
    );
    _loadData();
  }

  Future<void> _openForm({PresupuestoModel? p}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresupuestoFormScreen(presupuesto: p),
      ),
    );
    if (res == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.orange,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Barra de Búsqueda
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              borderRadius: 16,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente, trabajo o N°...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips de Filtro por Estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('TODOS', null),
                  ...PresupuestoModel.estadosValidos.map((st) {
                    return _buildFilterChip(st, AppColors.getEstadoColor(st));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Indicador de cantidad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_presupuestosFiltrados.length} Presupuestos',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                ),
                if (_presupuestosFiltrados.isNotEmpty)
                  Text(
                    'Total: ${Formatters.formatCurrency(_presupuestosFiltrados.fold(0.0, (acc, item) => acc + item.total))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.green),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de Presupuestos
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              )
            else if (_presupuestosFiltrados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 58,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay presupuestos que coincidan',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primer Presupuesto'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._presupuestosFiltrados.map((p) {
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  onTap: () => _openDetail(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: AppColors.orange, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.numeroPresupuesto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          EstadoBadge(estado: p.estado),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.nombreCliente,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.descripcionTrabajo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.glassBorder, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.formatDate(p.fechaEmision),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Row(
                            children: [
                              Text(
                                Formatters.formatCurrency(p.total),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, color: AppColors.green, size: 20),
                                tooltip: 'Compartir por WhatsApp',
                                onPressed: () async {
                                  if (_perfil != null) {
                                    await PdfService.instance.shareViaWhatsApp(
                                      presupuesto: p,
                                      perfil: _perfil!,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_nuevo_presupuesto',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Presupuesto'),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  Widget _buildFilterChip(String label, Color? color) {
    final isSelected = _filtroEstado == label;
    final chipColor = color ?? AppColors.orange;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: chipColor.withValues(alpha: 0.25),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.white.withValues(alpha: 0.1),
        ),
        labelStyle: TextStyle(
          color: isSelected ? (color ?? Colors.white) : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _filtroEstado = label;
            });
            _loadData();
          }
        },
      ),
    );
  }
}

