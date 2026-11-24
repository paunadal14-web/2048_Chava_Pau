import 'package:flutter/material.dart';

import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'tile_widget.dart';

// Fila de una partida en una lista
class PartidaListItem extends StatelessWidget {
  const PartidaListItem({
    super.key,
    required this.partida,
    this.posicion,
    this.onTap,
    this.onLongPress,
  });

  final Partida partida;

  // Si tiene posición se muestra como ranking
  final int? posicion;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final miniatura = TileWidget(
      valor: partida.fichaMaxima,
      lado: AppMedidas.fichaMiniatura,
    );

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: posicion == null
            ? miniatura
            : CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                child: Text(
                  '#$posicion',
                  style: TextStyle(color: tema.colorScheme.onPrimaryContainer),
                ),
              ),
        title: Text(
          '${partida.puntuacion} pts · ${partida.usuario ?? 'Jugador'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatearFecha(partida.fecha)} · '
          '${partida.movimientos} mov. · '
          '${formatearDuracion(partida.duracionSegundos)}',
        ),
        trailing: posicion == null ? const Icon(Icons.chevron_right) : miniatura,
      ),
    );
  }
}
