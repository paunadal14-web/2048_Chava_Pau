import 'package:flutter/widgets.dart';

import '../services/preferencias_service.dart';
import 'sesion_controller.dart';
import 'tema_controller.dart';

// Da acceso a los controladores desde cualquier pantalla
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.tema,
    required this.preferencias,
    required this.sesion,
    required super.child,
  });

  final TemaController tema;
  final PreferenciasService preferencias;
  final SesionController sesion;

  // Busca el AppScope en el árbol
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Falta AppScope encima de este widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      tema != oldWidget.tema ||
      preferencias != oldWidget.preferencias ||
      sesion != oldWidget.sesion;
}
