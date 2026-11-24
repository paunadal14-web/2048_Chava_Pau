import 'package:flutter/material.dart';

import 'app.dart';
import 'services/preferencias_service.dart';
import 'state/tema_controller.dart';

// Punto de entrada de la app
Future<void> main() async {
  // Prepara Flutter para usar plugins antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las preferencias guardadas (tema y paleta)
  final preferencias = await PreferenciasService.crear();
  final tema = TemaController(
    preferencias,
    modoInicial: await preferencias.leerModoTema(),
    paletaInicial: await preferencias.leerPaletaFichas(),
  );

  // Arranca la app
  runApp(Juego2048App(tema: tema, preferencias: preferencias));
}
