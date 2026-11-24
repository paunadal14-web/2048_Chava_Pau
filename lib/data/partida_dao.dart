import 'package:sqflite/sqflite.dart';

import '../models/estadisticas.dart';
import '../models/partida.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Consultas de la tabla partidas
class PartidaDao {
  PartidaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  // Atajos para los nombres de tabla
  static const String _tabPartidas = DatabaseHelper.tablaPartidas;
  static const String _tabUsuarios = DatabaseHelper.tablaUsuarios;
  static const String _tabGuardada = DatabaseHelper.tablaPartidaGuardada;

  // SELECT base con el nombre del jugador
  static const String _consultaBase = '''
    SELECT p.*, u.usuario AS usuario
    FROM $_tabPartidas p
    INNER JOIN $_tabUsuarios u ON u.id = p.usuario_id
  ''';

  // Inserta una partida (también para deshacer)
  Future<int> insertar(Partida partida) async {
    try {
      final db = await _helper.database;
      return await db.insert(
        _tabPartidas,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DatosException('Error al guardar la partida', e);
    }
  }

  // Transacción: guarda la partida y borra la guardada
  Future<int> finalizarPartida(Partida partida) async {
    try {
      final db = await _helper.database;
      return await db.transaction<int>((txn) async {
        final id = await txn.insert(_tabPartidas, partida.toMap());
        await txn.delete(_tabGuardada);
        return id;
      });
    } on DatabaseException catch (e) {
      throw DatosException('Error al registrar el final de la partida', e);
    }
  }

  // Historial con filtros opcionales
  Future<List<Partida>> obtenerHistorial({
    String? jugador,
    int? fichaMinima,
  }) async {
    final condiciones = <String>[];
    final argumentos = <Object?>[];

    final texto = jugador?.trim() ?? '';
    if (texto.isNotEmpty) {
      condiciones.add('u.usuario LIKE ?');
      argumentos.add('%$texto%');
    }
    if (fichaMinima != null) {
      condiciones.add('p.ficha_maxima >= ?');
      argumentos.add(fichaMinima);
    }

    // Une las condiciones con AND
    final where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_consultaBase $where ORDER BY p.fecha DESC',
        argumentos,
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('Error al cargar el historial', e);
    }
  }

  // Una partida por id
  Future<Partida?> obtenerPorId(int id) async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_consultaBase WHERE p.id = ? LIMIT 1',
        [id],
      );
      return filas.isEmpty ? null : Partida.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al cargar la partida', e);
    }
  }

  // Borra una partida
  Future<int> eliminar(int id) async {
    try {
      final db = await _helper.database;
      return await db.delete(_tabPartidas, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw DatosException('Error al eliminar la partida', e);
    }
  }

  // Borra todo el historial
  Future<int> eliminarTodo() async {
    try {
      final db = await _helper.database;
      return await db.delete(_tabPartidas);
    } on DatabaseException catch (e) {
      throw DatosException('Error al borrar el historial', e);
    }
  }

  // Las 10 mejores partidas
  Future<List<Partida>> obtenerTop10() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_consultaBase ORDER BY p.puntuacion DESC, p.fecha ASC LIMIT ?',
        [10],
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('Error al cargar el ranking', e);
    }
  }

  // COUNT, MAX, AVG y SUM de todas las partidas
  Future<EstadisticasGlobales> obtenerEstadisticasGlobales() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT COUNT(*)               AS partidas,
               MAX(puntuacion)        AS puntuacion_maxima,
               AVG(puntuacion)        AS puntuacion_media,
               MAX(ficha_maxima)      AS ficha_maxima,
               SUM(duracion_segundos) AS tiempo_total
        FROM $_tabPartidas
      ''');
      return EstadisticasGlobales.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudieron calcular las estadísticas', e);
    }
  }

  // Estadísticas agrupadas por jugador
  Future<List<EstadisticaJugador>> obtenerEstadisticasPorJugador() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT u.usuario         AS usuario,
               MAX(p.puntuacion) AS mejor_puntuacion,
               COUNT(p.id)       AS partidas
        FROM $_tabPartidas p
        INNER JOIN $_tabUsuarios u ON u.id = p.usuario_id
        GROUP BY p.usuario_id
        ORDER BY mejor_puntuacion DESC
      ''');
      return filas.map(EstadisticaJugador.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('No se pudieron calcular las estadísticas por jugador', e);
    }
  }

  // Mejor puntuación (global o de un usuario)
  Future<int> obtenerMejorPuntuacion({int? usuarioId}) async {
    try {
      final db = await _helper.database;
      final filas = usuarioId == null
          ? await db.rawQuery('SELECT MAX(puntuacion) FROM $_tabPartidas')
          : await db.rawQuery(
              'SELECT MAX(puntuacion) FROM $_tabPartidas WHERE usuario_id = ?',
              [usuarioId],
            );
      return Sqflite.firstIntValue(filas) ?? 0;
    } on DatabaseException catch (e) {
      throw DatosException('Error al leer la mejor puntuación', e);
    }
  }
}
