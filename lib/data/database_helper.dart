import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Abre y gestiona la base de datos (singleton)
class DatabaseHelper {
  DatabaseHelper._internal();

  // Única instancia compartida
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String nombreBD = 'game2048.db';

  // Versión actual del esquema
  static const int version = 2;

  // Nombres de las tablas
  static const String tablaUsuarios = 'usuarios';
  static const String tablaPartidas = 'partidas';
  static const String tablaPartidaGuardada = 'partida_guardada';

  Database? _db;

  // Devuelve la BD, abriéndola la primera vez
  Future<Database> get database async {
    return _db ??= await _abrirBD();
  }

  // Abre el archivo de la BD
  Future<Database> _abrirBD() async {
    final ruta = join(await getDatabasesPath(), nombreBD);
    return openDatabase(
      ruta,
      version: version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Activa las claves foráneas
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Instalación nueva: crea v1 y aplica migraciones
  Future<void> _onCreate(Database db, int version) async {
    await _crearTablasV1(db);
    await _onUpgrade(db, 1, version);
  }

  // Migraciones entre versiones
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _actualizarAV2(db);
    }
  }

  // Crea las tablas de la versión 1
  Future<void> _crearTablasV1(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tablaUsuarios (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario         TEXT    NOT NULL UNIQUE,
        fecha_registro  TEXT    NOT NULL,
        email           TEXT    NOT NULL UNIQUE,
        contrasena_hash TEXT    NOT NULL,
        salt            TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tablaPartidas (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id        INTEGER NOT NULL,
        puntuacion        INTEGER NOT NULL,
        ficha_maxima      INTEGER NOT NULL,
        movimientos       INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL,
        fecha             TEXT    NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tablaUsuarios (id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tablaPartidaGuardada (
        id                     INTEGER PRIMARY KEY CHECK (id = 1),
        usuario_id             INTEGER NOT NULL,
        tablero                TEXT    NOT NULL,
        puntuacion             INTEGER NOT NULL,
        movimientos            INTEGER NOT NULL,
        segundos_transcurridos INTEGER NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tablaUsuarios (id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute(
        'CREATE INDEX idx_partidas_usuario ON $tablaPartidas (usuario_id)');
    batch.execute(
        'CREATE INDEX idx_partidas_puntuacion ON $tablaPartidas (puntuacion DESC)');
    batch.execute('CREATE INDEX idx_partidas_fecha ON $tablaPartidas (fecha DESC)');

    await batch.commit(noResult: true);
  }

  // v2: añade el tamaño del tablero
  Future<void> _actualizarAV2(Database db) async {
    await db.execute(
      'ALTER TABLE $tablaPartidas '
      'ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4',
    );
  }

  // Cierra la conexión
  Future<void> cerrar() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}
