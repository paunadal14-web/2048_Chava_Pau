import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

// Todas las rutas de la app en un solo sitio
abstract final class AppRoutes {
  // Nombres de las rutas
  static const String login = '/login';
  static const String registro = '/registro';

  static const String home = '/';

  static const String juego = '/juego';

  static const String detalle = '/detalle';

  // Ruta con la que arranca la app
  static List<Route<dynamic>> rutasIniciales(String nombre) {
    return [generar(RouteSettings(name: nombre))];
  }

  // Devuelve la pantalla según el nombre de la ruta
  static Route<dynamic> generar(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _crearRuta(settings, const LoginScreen());
      case registro:
        return _crearRuta(settings, const RegistroScreen());
      case home:
        // Temporal hasta tener HomeShell
        return _crearRuta(
          settings,
          const Scaffold(body: Center(child: Text('Inicio (pendiente)'))),
        );
      default:
        return _rutaDesconocida(settings);
    }
  }

  // Crea la ruta de Material
  static MaterialPageRoute<T> _crearRuta<T>(RouteSettings settings, Widget pantalla) {
    return MaterialPageRoute<T>(settings: settings, builder: (_) => pantalla);
  }

  // Pantalla de error si la ruta no existe
  static Route<dynamic> _rutaDesconocida(RouteSettings settings) {
    return _crearRuta(
      settings,
      Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('No existe la ruta: ${settings.name}')),
      ),
    );
  }
}
