import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tarjeta de una estadística
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppEspaciado.m),
        child: Row(
          children: [
            Icon(icono, color: tema.colorScheme.primary),
            const SizedBox(width: AppEspaciado.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.textTheme.labelMedium),
                  Text(
                    valor,
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
