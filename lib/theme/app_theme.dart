import 'package:flutter/material.dart';

import '../models/paleta_fichas.dart';

// Espaciados
abstract final class AppEspaciado {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

// Tamaños y radios
abstract final class AppMedidas {
  static const double radioFicha = 10;
  static const double radioTablero = 12;
  static const double radioTarjeta = 16;
  static const double separacionCeldas = 8;
  static const double anchoMaxTablero = 460;
  static const double anchoMaxFormulario = 420;
  static const double fichaMiniatura = 44;
  static const double fichaDetalle = 96;
  static const double iconoGrande = 72;
  static const double altoStatCard = 84;

  // Mínimo de píxeles para contar un swipe
  static const double umbralSwipe = 20;
}

// Duraciones de las animaciones
abstract final class AppTiempos {
  static const Duration ficha = Duration(milliseconds: 120);
  static const Duration aparicion = Duration(milliseconds: 200);
}

// Estilos de texto
abstract final class AppEstilosTexto {
  static TextStyle tituloJuego(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w900);

  static TextStyle etiquetaMarcador(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          );

  static TextStyle valorMarcador(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);

  // Texto más pequeño cuantas más cifras
  static TextStyle ficha(double lado, int valor, Color color) {
    final cifras = valor.toString().length;
    final factor = switch (cifras) { 1 || 2 => 0.45, 3 => 0.36, 4 => 0.28, _ => 0.22 };
    return TextStyle(
      fontSize: lado * factor,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
}

// Colores del tablero y las fichas
@immutable
class ColoresFichasTheme extends ThemeExtension<ColoresFichasTheme> {
  const ColoresFichasTheme({
    required this.fondoTablero,
    required this.celdaVacia,
    required this.fichas,
    required this.textoOscuro,
    required this.textoClaro,
  });

  final Color fondoTablero;
  final Color celdaVacia;

  final List<Color> fichas;
  final Color textoOscuro;
  final Color textoClaro;

  static ColoresFichasTheme of(BuildContext context) =>
      Theme.of(context).extension<ColoresFichasTheme>()!;

  // Color según el valor de la ficha
  Color colorFicha(int valor) {
    if (valor <= 0) return celdaVacia;
    var indice = 0;
    var v = valor;
    while (v > 2) {
      v >>= 1;
      indice++;
    }
    return fichas[indice.clamp(0, fichas.length - 1)];
  }

  // Texto oscuro o claro según el fondo
  Color colorTexto(int valor) {
    final fondo = colorFicha(valor);
    return fondo.computeLuminance() > 0.45 ? textoOscuro : textoClaro;
  }

  @override
  ColoresFichasTheme copyWith({
    Color? fondoTablero,
    Color? celdaVacia,
    List<Color>? fichas,
    Color? textoOscuro,
    Color? textoClaro,
  }) {
    return ColoresFichasTheme(
      fondoTablero: fondoTablero ?? this.fondoTablero,
      celdaVacia: celdaVacia ?? this.celdaVacia,
      fichas: fichas ?? this.fichas,
      textoOscuro: textoOscuro ?? this.textoOscuro,
      textoClaro: textoClaro ?? this.textoClaro,
    );
  }

  @override
  ColoresFichasTheme lerp(ThemeExtension<ColoresFichasTheme>? other, double t) {
    if (other is! ColoresFichasTheme) return this;
    return ColoresFichasTheme(
      fondoTablero: Color.lerp(fondoTablero, other.fondoTablero, t)!,
      celdaVacia: Color.lerp(celdaVacia, other.celdaVacia, t)!,
      fichas: List.generate(
        fichas.length,
        (i) => Color.lerp(fichas[i], other.fichas[i], t)!,
      ),
      textoOscuro: Color.lerp(textoOscuro, other.textoOscuro, t)!,
      textoClaro: Color.lerp(textoClaro, other.textoClaro, t)!,
    );
  }
}

// Temas claro y oscuro
abstract final class AppTheme {
  static const Map<PaletaFichas, List<Color>> _paletas = {
    PaletaFichas.lavanda: [
      Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFFCE93D8), Color(0xFFBA68C8),
      Color(0xFFAB47BC), Color(0xFF9C27B0), Color(0xFF8E24AA), Color(0xFF7B1FA2),
      Color(0xFF6A1B9A), Color(0xFF5E35B1), Color(0xFF4527A0), Color(0xFF311B92),
    ],
    PaletaFichas.menta: [
      Color(0xFFE8F8F5), Color(0xFFC8F2E6), Color(0xFFA3E9D4), Color(0xFF7FDDC0),
      Color(0xFF5CCFAA), Color(0xFF3DBE94), Color(0xFF26A67F), Color(0xFF1B8C6B),
      Color(0xFF137257), Color(0xFF0E5C47), Color(0xFF0A4A3A), Color(0xFF06302A),
    ],
    PaletaFichas.coral: [
      Color(0xFFFFEBEE), Color(0xFFFFCDD2), Color(0xFFFFAB91), Color(0xFFFF8A80),
      Color(0xFFFF7262), Color(0xFFF4511E), Color(0xFFE53935), Color(0xFFD32F2F),
      Color(0xFFC2185B), Color(0xFFAD1457), Color(0xFF8E0038), Color(0xFF4E0020),
    ],
    PaletaFichas.medianoche: [
      Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9), Color(0xFF64B5F6),
      Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF3949AB), Color(0xFF303F9F),
      Color(0xFF283593), Color(0xFF1A237E), Color(0xFF0D1457), Color(0xFF050A30),
    ],
  };

  static const Color _semilla = Color(0xFF5C4DB1);

  static List<Color> coloresPaleta(PaletaFichas paleta) => _paletas[paleta]!;

  static ThemeData claro(PaletaFichas paleta) => _construir(Brightness.light, paleta);

  static ThemeData oscuro(PaletaFichas paleta) => _construir(Brightness.dark, paleta);

  // Crea el ThemeData
  static ThemeData _construir(Brightness brillo, PaletaFichas paleta) {
    final esOscuro = brillo == Brightness.dark;
    final esquema = ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo);
    final base = _paletas[paleta]!;

    // En oscuro las fichas son algo más oscuras
    final fichas = esOscuro
        ? base.map((c) {
            final hsl = HSLColor.fromColor(c);
            return hsl.withLightness((hsl.lightness * 0.8).clamp(0.0, 1.0)).toColor();
          }).toList()
        : base;

    final fichasTheme = ColoresFichasTheme(
      fondoTablero: esOscuro ? const Color(0xFF1C1A2B) : const Color(0xFFBDB7DA),
      celdaVacia: esOscuro ? const Color(0xFF2C2842) : const Color(0xFFDAD5EE),
      fichas: fichas,
      textoOscuro: const Color(0xFF2A2440),
      textoClaro: const Color(0xFFFFFFFF),
    );

    final redondeado = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brillo,
      extensions: [fichasTheme],
      cardTheme: CardThemeData(
        shape: redondeado,
        margin: const EdgeInsets.symmetric(
          horizontal: AppEspaciado.m,
          vertical: AppEspaciado.xs,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: redondeado,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: redondeado,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
