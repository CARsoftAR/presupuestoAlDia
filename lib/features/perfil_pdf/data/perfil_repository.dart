import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:presupuesto_al_dia/core/database/app_database.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';

class PerfilRepository {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<PerfilModel> getPerfil() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'perfil_electricista',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return PerfilModel.fromMap(maps.first);
    } else {
      final defaultPerfil = PerfilModel(
        id: 1,
        nombreEmpresa: 'ElectroServicios Pro',
        nombreElectricista: 'Electricista Matriculado',
        matricula: 'COPIME Mat. N° 45892',
        direccion: 'Av. Rivadavia 4520, CABA',
        telefono: '+54 9 11 5555-1234',
        email: 'contacto@electroservicios.com',
        cuerpoMensajeDefault:
            'Estimado cliente, adjunto el presupuesto detallado para las obras e instalaciones eléctricas solicitadas.',
        piePagina:
            'Presupuesto válido por 15 días. Trabajos garantizados conforme a normas de seguridad eléctrica vigentes.',
      );
      await savePerfil(defaultPerfil);
      return defaultPerfil;
    }
  }

  Future<void> savePerfil(PerfilModel perfil) async {
    final db = await _dbProvider.database;
    await db.insert(
      'perfil_electricista',
      perfil.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

