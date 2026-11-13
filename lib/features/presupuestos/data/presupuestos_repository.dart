import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:presupuesto_al_dia/core/database/app_database.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';

class PresupuestosRepository {
  final AppDatabase _dbProvider = AppDatabase.instance;

  /// Genera un número correlativo limpio automático (ej. #P-0001)
  Future<String> generateNextNumeroPresupuesto() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> res = await db.rawQuery(
      'SELECT MAX(id) as max_id FROM presupuestos',
    );
    final maxId = (res.first['max_id'] as int?) ?? 0;
    final nextId = maxId + 1;
    return '#P-${nextId.toString().padLeft(4, '0')}';
  }

  /// Lista presupuestos con filtro opcional de estado
  Future<List<PresupuestoModel>> getAllPresupuestos({String? estado}) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps;

    if (estado != null && estado.isNotEmpty && estado != 'TODOS') {
      maps = await db.query(
        'presupuestos',
        where: 'estado = ?',
        whereArgs: [estado.toUpperCase().trim()],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query(
        'presupuestos',
        orderBy: 'id DESC',
      );
    }

    final List<PresupuestoModel> list = [];
    for (final map in maps) {
      final int id = map['id'] as int;
      final items = await getItemsForPresupuesto(id, db: db);
      list.add(PresupuestoModel.fromMap(map, items: items));
    }
    return list;
  }

  /// Obtiene el detalle completo de un presupuesto con sus ítems
  Future<PresupuestoModel?> getPresupuestoById(int id) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final items = await getItemsForPresupuesto(id, db: db);
    return PresupuestoModel.fromMap(maps.first, items: items);
  }

  /// Obtiene los ítems o materiales asociados a un presupuesto
  Future<List<PresupuestoItemModel>> getItemsForPresupuesto(int presupuestoId, {Database? db}) async {
    final database = db ?? await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await database.query(
      'presupuesto_materiales',
      where: 'presupuesto_id = ?',
      whereArgs: [presupuestoId],
      orderBy: 'id ASC',
    );

    return maps.map((m) => PresupuestoItemModel.fromMap(m)).toList();
  }

  /// Alias de compatibilidad
  Future<List<PresupuestoItemModel>> getMaterialesForPresupuesto(int presupuestoId, {Database? db}) =>
      getItemsForPresupuesto(presupuestoId, db: db);

  /// Guarda de forma atómica un presupuesto y todos sus ítems
  Future<int> createPresupuesto(PresupuestoModel presupuesto) async {
    final db = await _dbProvider.database;

    // Recalcular el total exacto a partir de los ítems
    final double totalCalculado = presupuesto.items.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    final presupuestoFinal = presupuesto.copyWith(total: totalCalculado);

    return await db.transaction<int>((txn) async {
      // 1. Insertar cabecera del presupuesto
      final map = presupuestoFinal.toMap();
      map.remove('id');
      final newId = await txn.insert('presupuestos', map);

      // 2. Insertar cada ítem asociado
      for (final item in presupuestoFinal.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['presupuesto_id'] = newId;
        await txn.insert('presupuesto_materiales', itemMap);
      }

      return newId;
    });
  }

  /// Actualiza atómicamente un presupuesto y reemplaza sus ítems recalculando el total
  Future<void> updatePresupuesto(PresupuestoModel presupuesto) async {
    if (presupuesto.id == null) return;
    final db = await _dbProvider.database;

    // Recalcular el total exacto
    final double totalCalculado = presupuesto.items.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    final presupuestoFinal = presupuesto.copyWith(total: totalCalculado);

    await db.transaction((txn) async {
      // 1. Actualizar cabecera
      await txn.update(
        'presupuestos',
        presupuestoFinal.toMap(),
        where: 'id = ?',
        whereArgs: [presupuestoFinal.id],
      );

      // 2. Eliminar ítems anteriores
      await txn.delete(
        'presupuesto_materiales',
        where: 'presupuesto_id = ?',
        whereArgs: [presupuestoFinal.id],
      );

      // 3. Reinsertar los nuevos ítems
      for (final item in presupuestoFinal.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['presupuesto_id'] = presupuestoFinal.id;
        await txn.insert('presupuesto_materiales', itemMap);
      }
    });
  }

  /// Cambia rápidamente el estado de un presupuesto
  Future<void> updateEstado(int id, String nuevoEstado) async {
    final db = await _dbProvider.database;
    await db.update(
      'presupuestos',
      {'estado': nuevoEstado.toUpperCase().trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un presupuesto y sus ítems en cascada
  Future<void> deletePresupuesto(int id) async {
    final db = await _dbProvider.database;
    await db.delete(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
