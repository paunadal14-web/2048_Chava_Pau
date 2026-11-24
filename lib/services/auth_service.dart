import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../data/datos_exception.dart';
import '../data/usuario_dao.dart';
import '../models/usuario.dart';

// Error de login o registro
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

// Registro, login y validaciones
class AuthService {
  AuthService(this._usuarioDao);

  final UsuarioDao _usuarioDao;

  static final RegExp _patronEmail = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static const int longitudMinimaContrasena = 6;
  static const int _rondasHash = 1200;

  // Validaciones de los formularios
  static String? validarUsuario(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Introduce un nombre de usuario';
    if (v.length < 3) return 'Al menos 3 caracteres';
    return null;
  }

  static String? validarEmail(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Introduce un email';
    if (!v.contains('@') || !_patronEmail.hasMatch(v)) {
      return 'Email no válido';
    }
    return null;
  }

  static String? validarContrasena(String? valor) {
    final v = valor ?? '';
    if (v.length < longitudMinimaContrasena) {
      return 'Al menos $longitudMinimaContrasena caracteres';
    }
    return null;
  }

  // Crea la cuenta con la contraseña hasheada
  Future<Usuario> registrar({
    required String usuario,
    required String email,
    required String contrasena,
  }) async {
    final salt = _nuevoSalt();
    final nuevo = Usuario(
      usuario: usuario.trim(),
      fechaRegistro: DateTime.now(),
      email: email.trim().toLowerCase(),
      contrasenaHash: hashContrasena(contrasena, salt),
      salt: salt,
    );
    try {
      return await _usuarioDao.insertar(nuevo);
    } on DatosException catch (e) {
      throw AuthException(e.mensaje);
    }
  }

  // Comprueba usuario y contraseña
  Future<Usuario> iniciarSesion(String identificador, String contrasena) async {
    final Usuario? usuario;
    try {
      usuario = await _usuarioDao.buscarPorUsuarioOEmail(identificador.trim());
    } on DatosException catch (e) {
      throw AuthException(e.mensaje);
    }
    if (usuario == null ||
        hashContrasena(contrasena, usuario.salt) != usuario.contrasenaHash) {
      throw const AuthException('Usuario o contraseña incorrectos');
    }
    return usuario;
  }

  Future<Usuario?> buscarPorId(int id) => _usuarioDao.buscarPorId(id);

  // SHA-256 con salt repetido varias veces
  static String hashContrasena(String contrasena, String salt) {
    List<int> bytes = utf8.encode('$salt$contrasena');
    for (var i = 0; i < _rondasHash; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  // Salt aleatorio
  static String _nuevoSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
