import 'package:flutter/material.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/presupuestos/data/presupuestos_repository.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_estado.dart';
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

  List<PresupuestoModel> _presupuestos = [];
  bool _isLoading = true;
  String _filtroEstado = 'TODOS';
  String _searchQuery = '';

  // Paleta minimalista modo claro
  static const Color orangeAccent = Color(0xFFFF6B00);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);

  final List<String> _estadosFiltro = [
    'TODOS',
    'BORRADOR',
    'PENDIENTE',
    'EMITIDO',
    'ACEPTADO',
    'CANCELADO',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _repo.getAllPresupuestos(
      estado: _filtroEstado == 'TODOS' ? null : _filtroEstado,
    );
    if (mounted) {
      setState(() {
        _presupuestos = list;
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: orangeAccent,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Buscador minimalista
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(fontSize: 13, color: textDark),
                decoration: const InputDecoration(
                  hintText: 'Buscar por cliente, N° o trabajo...',
                  hintStyle: TextStyle(color: textGray, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: textGray, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Barra horizontal de filtros por estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _estadosFiltro.map((estado) {
                  final isSelected = _filtroEstado == estado;
                  final Color activeColor = estado == 'TODOS'
                      ? orangeAccent
                      : EstadoPresupuesto.desdeString(estado).colorTexto;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() => _filtroEstado = estado);
                        _loadData();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? activeColor : borderColor,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Text(
                          estado == 'TODOS' ? 'Todos' : estado.substring(0, 1) + estado.substring(1).toLowerCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? activeColor : textDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Contador de presupuestos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_presupuestosFiltrados.length} presupuestos',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textGray,
                  ),
                ),
                if (_presupuestosFiltrados.isNotEmpty)
                  Text(
                    'Total: ${Formatters.formatCurrency(_presupuestosFiltrados.fold(0.0, (acc, item) => acc + item.total))}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: greenAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de Tarjetas de Presupuestos
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: orangeAccent),
                ),
              )
            else if (_presupuestosFiltrados.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.request_quote_outlined,
                        size: 48,
                        color: textGray.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay presupuestos que coincidan',
                        style: TextStyle(color: textGray, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nuevo Presupuesto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._presupuestosFiltrados.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openDetail(p),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila N° y Badge de Estado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: orangeAccent, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.numeroPresupuesto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Formatters.formatDate(p.fechaEmision),
                                      style: const TextStyle(fontSize: 11, color: textGray),
                                    ),
                                  ],
                                ),
                                EstadoBadge(estado: p.estado),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Nombre del Cliente
                            Text(
                              p.nombreCliente,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Resumen breve del trabajo
                            Text(
                              p.descripcionTrabajo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: textGray, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            const Divider(color: borderColor, height: 1),
                            const SizedBox(height: 8),

                            // Total general y cantidad de ítems
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${p.items.length} ${p.items.length == 1 ? "ítem" : "ítems"}',
                                  style: const TextStyle(fontSize: 12, color: textGray),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'TOTAL: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textGray,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(p.total),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_nuevo_presupuesto_minimalista',
        onPressed: () => _openForm(),
        backgroundColor: orangeAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Nuevo Presupuesto',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
