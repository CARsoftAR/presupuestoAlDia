import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:presupuesto_al_dia/core/database/app_database.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/material_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';

class PresupuestosRepository {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<String> generateNextNumeroPresupuesto() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> res = await db.rawQuery(
      'SELECT MAX(id) as max_id FROM presupuestos',
    );
    final maxId = (res.first['max_id'] as int?) ?? 0;
    final nextId = maxId + 1;
    final year = DateTime.now().year;
    return 'PRE-$year-${nextId.toString().padLeft(4, '0')}';
  }

  Future<List<PresupuestoModel>> getAllPresupuestos({String? estado}) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps;

    if (estado != null && estado.isNotEmpty && estado != 'TODOS') {
      maps = await db.query(
        'presupuestos',
        where: 'estado = ?',
        whereArgs: [estado],
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
      final materiales = await getMaterialesForPresupuesto(id, db: db);
      list.add(PresupuestoModel.fromMap(map, materiales: materiales));
    }
    return list;
  }

  Future<PresupuestoModel?> getPresupuestoById(int id) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final materiales = await getMaterialesForPresupuesto(id, db: db);
    return PresupuestoModel.fromMap(maps.first, materiales: materiales);
  }

  Future<List<MaterialItemModel>> getMaterialesForPresupuesto(int presupuestoId, {Database? db}) async {
    final database = db ?? await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await database.query(
      'presupuesto_materiales',
      where: 'presupuesto_id = ?',
      whereArgs: [presupuestoId],
      orderBy: 'id ASC',
    );

    return maps.map((m) => MaterialItemModel.fromMap(m)).toList();
  }

  Future<int> createPresupuesto(PresupuestoModel presupuesto) async {
    final db = await _dbProvider.database;

    return await db.transaction<int>((txn) async {
      // 1. Insertar presupuesto
      final presupuestoMap = presupuesto.toMap();
      presupuestoMap.remove('id');
      final newId = await txn.insert('presupuestos', presupuestoMap);

      // 2. Insertar materiales
      for (final mat in presupuesto.materiales) {
        final matMap = mat.toMap();
        matMap.remove('id');
        matMap['presupuesto_id'] = newId;
        await txn.insert('presupuesto_materiales', matMap);
      }

      return newId;
    });
  }

  Future<void> updatePresupuesto(PresupuestoModel presupuesto) async {
    if (presupuesto.id == null) return;
    final db = await _dbProvider.database;

    await db.transaction((txn) async {
      // 1. Actualizar presupuesto
      await txn.update(
        'presupuestos',
        presupuesto.toMap(),
        where: 'id = ?',
        whereArgs: [presupuesto.id],
      );

      // 2. Eliminar materiales existentes para reemplazar
      await txn.delete(
        'presupuesto_materiales',
        where: 'presupuesto_id = ?',
        whereArgs: [presupuesto.id],
      );

      // 3. Reinsertar materiales actualizados
      for (final mat in presupuesto.materiales) {
        final matMap = mat.toMap();
        matMap.remove('id');
        matMap['presupuesto_id'] = presupuesto.id;
        await txn.insert('presupuesto_materiales', matMap);
      }
    });
  }

  Future<void> updateEstado(int id, String nuevoEstado) async {
    final db = await _dbProvider.database;
    await db.update(
      'presupuestos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePresupuesto(int id) async {
    final db = await _dbProvider.database;
    // ON DELETE CASCADE se encarga de presupuesto_materiales gracias a PRAGMA foreign_keys = ON
    await db.delete(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

