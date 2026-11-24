import 'package:sqflite/sqflite.dart';

import '../models/partida_guardada.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Consultas de la partida en curso
class PartidaGuardadaDao {
  PartidaGuardadaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;
  static const String _tabla = DatabaseHelper.tablaPartidaGuardada;

  // Guarda o reemplaza la partida en curso
  Future<void> guardar(PartidaGuardada partida) async {
    try {
      final db = await _helper.database;
      await db.insert(
        _tabla,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DatosException('Error al guardar la partida en curso', e);
    }
  }

  // Recupera la partida del usuario
  Future<PartidaGuardada?> obtener(int usuarioId) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [PartidaGuardada.idUnico, usuarioId],
        limit: 1,
      );
      return filas.isEmpty ? null : PartidaGuardada.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al recuperar la partida en curso', e);
    }
  }

  // Indica si hay partida guardada
  Future<bool> existe(int usuarioId) async => (await obtener(usuarioId)) != null;

  // Borra la partida en curso
  Future<void> eliminar() async {
    try {
      final db = await _helper.database;
      await db.delete(
        _tabla,
        where: 'id = ?',
        whereArgs: [PartidaGuardada.idUnico],
      );
    } on DatabaseException catch (e) {
      throw DatosException('Error al borrar la partida en curso', e);
    }
  }
}
