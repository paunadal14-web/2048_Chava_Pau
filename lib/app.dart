import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/preferencias_service.dart';
import 'state/app_scope.dart';
import 'state/tema_controller.dart';
import 'theme/app_theme.dart';

// Widget raíz: configura tema y rutas
class Juego2048App extends StatelessWidget {
  const Juego2048App({super.key, required this.tema, required this.preferencias});

  final TemaController tema;
  final PreferenciasService preferencias;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      tema: tema,
      preferencias: preferencias,
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
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generar,
          onGenerateInitialRoutes: AppRoutes.rutasIniciales,
        ),
      ),
    );
  }
}
