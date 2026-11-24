import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/preferencias_service.dart';
import 'state/app_scope.dart';
import 'state/sesion_controller.dart';
import 'state/tema_controller.dart';
import 'theme/app_theme.dart';

// Widget raíz: configura tema y rutas
class Juego2048App extends StatelessWidget {
  const Juego2048App({
    super.key,
    required this.tema,
    required this.preferencias,
    required this.sesion,
  });

  final TemaController tema;
  final PreferenciasService preferencias;
  final SesionController sesion;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      tema: tema,
      preferencias: preferencias,
      sesion: sesion,
      // Se reconstruye cuando cambia el tema
      child: ListenableBuilder(
        listenable: tema,
        builder: (context, _) => MaterialApp(
          title: '2048 Flutter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(tema.paleta),
          darkTheme: AppTheme.oscuro(tema.paleta),
          themeMode: tema.modo,
          // Si hay sesión va a Home, si no al login
          initialRoute: sesion.haySesion ? AppRoutes.home : AppRoutes.login,
          onGenerateRoute: AppRoutes.generar,
          onGenerateInitialRoutes: AppRoutes.rutasIniciales,
        ),
      ),
    );
  }
}
