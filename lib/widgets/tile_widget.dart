import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Una ficha del tablero
class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.valor,
    required this.lado,
    this.esNueva = false,
    this.esFusion = false,
  });

  final int valor;
  final double lado;
  final bool esNueva;
  final bool esFusion;

  @override
  Widget build(BuildContext context) {
    final fichas = ColoresFichasTheme.of(context);

    final ficha = Semantics(
      label: valor == 0 ? 'Celda vacía' : 'Ficha $valor',
      child: AnimatedContainer(
        duration: AppTiempos.ficha,
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fichas.colorFicha(valor),
          borderRadius: BorderRadius.circular(AppMedidas.radioFicha),
        ),
        child: valor == 0
            ? null
            : Text(
                '$valor',
                style: AppEstilosTexto.ficha(lado, valor, fichas.colorTexto(valor)),
              ),
      ),
    );

    // Animación de escala al aparecer o fusionar
    if (!esNueva && !esFusion) return ficha;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: esNueva ? 0.0 : 1.2, end: 1.0),
      duration: AppTiempos.aparicion,
      curve: esNueva ? Curves.easeOutBack : Curves.easeOut,
      builder: (context, escala, child) =>
          Transform.scale(scale: escala, child: child),
      child: ficha,
    );
  }
}
