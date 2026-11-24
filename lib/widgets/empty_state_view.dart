import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Mensaje cuando no hay datos
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icono,
    required this.mensaje,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String mensaje;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppEspaciado.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: AppMedidas.iconoGrande,
              color: tema.colorScheme.outline,
            ),
            const SizedBox(height: AppEspaciado.m),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            if (detalle != null) ...[
              const SizedBox(height: AppEspaciado.s),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
            if (accion != null) ...[
              const SizedBox(height: AppEspaciado.l),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
