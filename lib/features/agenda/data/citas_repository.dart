import 'package:presupuesto_al_dia/core/database/app_database.dart';
import 'package:presupuesto_al_dia/core/services/notification_service.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';

class CitasRepository {
  final AppDatabase _dbProvider = AppDatabase.instance;
  final NotificationService _notifications = NotificationService.instance;

  Future<List<Cita>> getAllCitas({bool? soloPendientes}) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps;

    if (soloPendientes == true) {
      maps = await db.query(
        'citas',
        where: 'completada = 0',
        orderBy: 'fecha_hora_visita ASC',
      );
    } else {
      maps = await db.query(
        'citas',
        orderBy: 'fecha_hora_visita ASC',
      );
    }

    return maps.map((m) => Cita.fromMap(m)).toList();
  }

  Future<List<Cita>> getCitasByDate(DateTime date) async {
    final db = await _dbProvider.database;
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'citas',
      where: 'fecha_hora_visita >= ? AND fecha_hora_visita <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'fecha_hora_visita ASC',
    );

    return maps.map((m) => Cita.fromMap(m)).toList();
  }

  Future<Cita?> getCitaById(int id) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Cita.fromMap(maps.first);
  }

  Future<int> createCita(Cita cita) async {
    final db = await _dbProvider.database;
    final map = cita.toMap();
    map.remove('id');

    final id = await db.insert('citas', map);

    // Al crear con alarma activa (> 0) y no completada: programar alarma
    if (!cita.completada && cita.minutosAlarma > 0) {
      await _notifications.programarAlarmaCita(
        citaId: id,
        cliente: cita.nombreCliente,
        direccion: cita.direccion,
        establecimiento: cita.establecimiento,
        fechaHoraVisita: cita.fechaHoraVisita,
        minutosAntes: cita.minutosAlarma,
      );
    }

    return id;
  }

  Future<void> updateCita(Cita cita) async {
    if (cita.id == null) return;
    final db = await _dbProvider.database;

    await db.update(
      'citas',
      cita.toMap(),
      where: 'id = ?',
      whereArgs: [cita.id],
    );

    // Si la cita está completada o la alarma desactivada (<= 0), cancelar
    if (cita.completada || cita.minutosAlarma <= 0) {
      await _notifications.cancelarAlarmaCita(cita.id!);
    } else {
      // Reprogramar con la nueva configuración
      await _notifications.programarAlarmaCita(
        citaId: cita.id!,
        cliente: cita.nombreCliente,
        direccion: cita.direccion,
        establecimiento: cita.establecimiento,
        fechaHoraVisita: cita.fechaHoraVisita,
        minutosAntes: cita.minutosAlarma,
      );
    }
  }

  Future<void> toggleCompletada(int id, bool completada) async {
    final db = await _dbProvider.database;
    await db.update(
      'citas',
      {'completada': completada ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (completada) {
      await _notifications.cancelarAlarmaCita(id);
    } else {
      final cita = await getCitaById(id);
      if (cita != null && cita.minutosAlarma > 0) {
        await _notifications.programarAlarmaCita(
          citaId: cita.id!,
          cliente: cita.nombreCliente,
          direccion: cita.direccion,
          establecimiento: cita.establecimiento,
          fechaHoraVisita: cita.fechaHoraVisita,
          minutosAntes: cita.minutosAlarma,
        );
      }
    }
  }

  Future<void> toggleAlarma(int id, bool activar, {int minutosSiActiva = 60}) async {
    final db = await _dbProvider.database;
    final nuevoValorMinutos = activar ? (minutosSiActiva > 0 ? minutosSiActiva : 60) : 0;

    await db.update(
      'citas',
      {'minutos_anticipacion_alarma': nuevoValorMinutos},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (!activar) {
      await _notifications.cancelarAlarmaCita(id);
    } else {
      final cita = await getCitaById(id);
      if (cita != null && !cita.completada) {
        await _notifications.programarAlarmaCita(
          citaId: cita.id!,
          cliente: cita.nombreCliente,
          direccion: cita.direccion,
          establecimiento: cita.establecimiento,
          fechaHoraVisita: cita.fechaHoraVisita,
          minutosAntes: nuevoValorMinutos,
        );
      }
    }
  }

  Future<void> deleteCita(int id) async {
    final db = await _dbProvider.database;
    await db.delete(
      'citas',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cancelar la alarma programada
    await _notifications.cancelarAlarmaCita(id);
  }
}
