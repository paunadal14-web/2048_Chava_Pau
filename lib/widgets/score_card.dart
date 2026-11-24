import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Marcador con etiqueta y valor
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.onDoubleTap,
  });

  final String etiqueta;
  final int valor;

  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 90),
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspaciado.m,
          vertical: AppEspaciado.s,
        ),
        decoration: BoxDecoration(
          color: esquema.primaryContainer,
          borderRadius: BorderRadius.circular(AppMedidas.radioFicha),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta.toUpperCase(),
              style: AppEstilosTexto.etiquetaMarcador(context)
                  .copyWith(color: esquema.onPrimaryContainer),
            ),
            Text(
              '$valor',
              style: AppEstilosTexto.valorMarcador(context)
                  .copyWith(color: esquema.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
