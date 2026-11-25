import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/entrenamiento.dart';

class DbService {
  static final DbService instancia = DbService._();
  DbService._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final carpeta = await getDatabasesPath();
    final ruta = join(carpeta, 'fitness.db');
    return openDatabase(
      ruta,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entrenamientos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            duracion INTEGER NOT NULL,
            pasos INTEGER NOT NULL,
            distancia REAL NOT NULL,
            ruta TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS usuarios (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<bool> registrarUsuario(String nombre, String email, String password) async {
    final db = await _database;
    try {
      await db.insert('usuarios', {
        'nombre': nombre,
        'email': email.toLowerCase(),
        'password': password,
      });
      return true;
    } catch (_) {
      return false; // Email duplicado o error
    }
  }

  Future<Map<String, dynamic>?> validarUsuario(String email, String password) async {
    final db = await _database;
    final filas = await db.query(
      'usuarios',
      where: 'email = ? AND password = ?',
      whereArgs: [email.toLowerCase(), password],
    );
    if (filas.isNotEmpty) {
      return filas.first;
    }
    return null;
  }

  Future<int> guardar(Entrenamiento e) async {
    final db = await _database;
    return db.insert('entrenamientos', e.toMap()..remove('id'));
  }

  Future<List<Entrenamiento>> obtenerTodos() async {
    final db = await _database;
    final filas = await db.query('entrenamientos', orderBy: 'fecha DESC');
    return filas.map(Entrenamiento.fromMap).toList();
  }

  Future<void> eliminar(int id) async {
    final db = await _database;
    await db.delete('entrenamientos', where: 'id = ?', whereArgs: [id]);
  }
}