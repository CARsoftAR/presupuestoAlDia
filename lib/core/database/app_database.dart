import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Si estamos en desktop (Windows, Linux, macOS), inicializamos el factory FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'PresupuestoAlDia'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      dbPath = p.join(dir.path, 'presupuesto_al_dia.db');
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'presupuesto_al_dia.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        // 1. Tabla de perfil del electricista
        await db.execute('''
          CREATE TABLE perfil_electricista (
            id INTEGER PRIMARY KEY,
            nombre_empresa TEXT,
            nombre_electricista TEXT,
            matricula TEXT,
            direccion TEXT,
            telefono TEXT,
            email TEXT,
            ruta_imagen_cabecera TEXT,
            cuerpo_mensaje_default TEXT,
            pie_pagina TEXT
          );
        ''');

        // 2. Tabla de citas de la agenda
        await db.execute('''
          CREATE TABLE citas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre_cliente TEXT NOT NULL,
            establecimiento TEXT,
            direccion TEXT NOT NULL,
            celular TEXT NOT NULL,
            fecha_hora_visita TEXT NOT NULL,
            minutos_anticipacion_alarma INTEGER NOT NULL DEFAULT 60,
            notas TEXT,
            completada INTEGER DEFAULT 0
          );
        ''');

        // 3. Tabla de presupuestos
        await db.execute('''
          CREATE TABLE presupuestos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            numero_presupuesto TEXT,
            nombre_cliente TEXT NOT NULL,
            direccion TEXT,
            celular TEXT,
            fecha_emision TEXT NOT NULL,
            validez_dias INTEGER DEFAULT 15,
            estado TEXT NOT NULL DEFAULT 'BORRADOR',
            descripcion_trabajo TEXT NOT NULL,
            cuerpo_mensaje TEXT,
            total REAL NOT NULL DEFAULT 0.0
          );
        ''');

        // 4. Tabla de materiales del presupuesto
        await db.execute('''
          CREATE TABLE presupuesto_materiales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            presupuesto_id INTEGER NOT NULL,
            descripcion TEXT NOT NULL,
            cantidad REAL NOT NULL DEFAULT 1,
            unidad TEXT DEFAULT 'un.',
            precio_unitario REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (presupuesto_id) REFERENCES presupuestos (id) ON DELETE CASCADE
          );
        ''');

        // Insertar perfil inicial por defecto
        await db.insert('perfil_electricista', {
          'id': 1,
          'nombre_empresa': 'ElectroServicios Pro',
          'nombre_electricista': 'Electricista Matriculado',
          'matricula': 'COPIME Mat. N° 45892',
          'direccion': 'Av. Rivadavia 4520, CABA',
          'telefono': '+54 9 11 5555-1234',
          'email': 'contacto@electroservicios.com',
          'ruta_imagen_cabecera': null,
          'cuerpo_mensaje_default': 'Estimado cliente, adjunto el presupuesto detallado para las obras e instalaciones eléctricas solicitadas. Cualquier consulta estamos a su disposición.',
          'pie_pagina': 'Presupuesto válido por 15 días. Trabajos garantizados conforme a normas de seguridad eléctrica vigentes.',
        });
      },
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

