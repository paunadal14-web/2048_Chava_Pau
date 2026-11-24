import 'package:flutter/material.dart';

import '../models/paleta_fichas.dart';
import '../services/preferencias_service.dart';

// Guarda el tema actual y avisa cuando cambia
class TemaController extends ChangeNotifier {
  TemaController(
    this._preferencias, {
    required ThemeMode modoInicial,
    required PaletaFichas paletaInicial,
  })  : _modo = modoInicial,
        _paleta = paletaInicial;

  final PreferenciasService _preferencias;

  ThemeMode _modo;
  PaletaFichas _paleta;

  ThemeMode get modo => _modo;
  PaletaFichas get paleta => _paleta;

  // Cambia claro/oscuro/sistema y lo guarda
  Future<void> cambiarModo(ThemeMode modo) async {
    if (modo == _modo) return;
    _modo = modo;
    notifyListeners();
    await _preferencias.guardarModoTema(modo);
  }

  // Cambia la paleta y la guarda
  Future<void> cambiarPaleta(PaletaFichas paleta) async {
    if (paleta == _paleta) return;
    _paleta = paleta;
    notifyListeners();
    await _preferencias.guardarPaletaFichas(paleta);
  }
}
