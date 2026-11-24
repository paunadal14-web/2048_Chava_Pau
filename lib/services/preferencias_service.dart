import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paleta_fichas.dart';

// Acceso a SharedPreferences
class PreferenciasService {
  PreferenciasService(this._prefs);

  // Crea el servicio ya inicializado
  static Future<PreferenciasService> crear() async {
    return PreferenciasService(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  // Claves guardadas
  static const String claveModoTema = 'modo_tema';
  static const String clavePaletaFichas = 'paleta_fichas';
  static const String claveUltimoJugador = 'ultimo_jugador';
  static const String claveMejorPuntuacion = 'mejor_puntuacion';
  static const String claveVibracion = 'vibracion';
  static const String claveSesionUsuarioId = 'sesion_usuario_id';

  // Tema (por defecto el del sistema)
  Future<void> guardarModoTema(ThemeMode modo) async {
    await _prefs.setString(claveModoTema, modo.name);
  }

  Future<ThemeMode> leerModoTema() async {
    final valor = _prefs.getString(claveModoTema);
    return ThemeMode.values.firstWhere(
      (m) => m.name == valor,
      orElse: () => ThemeMode.system,
    );
  }

  // Paleta de fichas
  Future<void> guardarPaletaFichas(PaletaFichas paleta) async {
    await _prefs.setString(clavePaletaFichas, paleta.name);
  }

  Future<PaletaFichas> leerPaletaFichas() async {
    final valor = _prefs.getString(clavePaletaFichas);
    return PaletaFichas.values.firstWhere(
      (p) => p.name == valor,
      orElse: () => PaletaFichas.lavanda,
    );
  }

  // Último jugador (para el login)
  Future<void> guardarUltimoJugador(String nombre) async {
    await _prefs.setString(claveUltimoJugador, nombre);
  }

  Future<String?> leerUltimoJugador() async => _prefs.getString(claveUltimoJugador);

  // Guarda la puntuación si es récord
  Future<bool> actualizarMejorPuntuacion(int puntuacion) async {
    final actual = await leerMejorPuntuacion();
    if (puntuacion > actual) {
      await _prefs.setInt(claveMejorPuntuacion, puntuacion);
      return true;
    }
    return false;
  }

  Future<int> leerMejorPuntuacion() async => _prefs.getInt(claveMejorPuntuacion) ?? 0;

  Future<void> reiniciarMejorPuntuacion() async {
    await _prefs.remove(claveMejorPuntuacion);
  }

  // Vibración activada o no
  Future<void> guardarVibracion(bool activa) async {
    await _prefs.setBool(claveVibracion, activa);
  }

  Future<bool> leerVibracion() async => _prefs.getBool(claveVibracion) ?? true;

  // Sesión abierta
  Future<void> guardarSesion(int usuarioId) async {
    await _prefs.setInt(claveSesionUsuarioId, usuarioId);
  }

  Future<int?> leerSesion() async => _prefs.getInt(claveSesionUsuarioId);

  Future<void> borrarSesion() async {
    await _prefs.remove(claveSesionUsuarioId);
  }
}
