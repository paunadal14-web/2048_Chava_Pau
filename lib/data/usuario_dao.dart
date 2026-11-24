import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Consultas de la tabla usuarios
class UsuarioDao {
  UsuarioDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;
  static const String _tabla = DatabaseHelper.tablaUsuarios;

  // Registra un usuario nuevo
  Future<Usuario> insertar(Usuario usuario) async {
    try {
      final db = await _helper.database;
      final id = await db.insert(
        _tabla,
        usuario.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return usuario.copyWith(id: id);
    } on DatabaseException catch (e) {
      // Usuario o email repetido
      if (e.isUniqueConstraintError()) {
        throw DatosException('Ese nombre de usuario o email ya está registrado', e);
      }
      throw DatosException('Error al registrar el usuario', e);
    }
  }

  // Busca por nombre o email (sin mayúsculas)
  Future<Usuario?> buscarPorUsuarioOEmail(String identificador) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'usuario = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
        whereArgs: [identificador, identificador],
        limit: 1,
      );
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al buscar el usuario', e);
    }
  }

  // Busca por id
  Future<Usuario?> buscarPorId(int id) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al cargar el usuario', e);
    }
  }
}
