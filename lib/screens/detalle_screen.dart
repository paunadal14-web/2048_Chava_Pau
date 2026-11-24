import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/stat_card.dart';
import '../widgets/tile_widget.dart';

// Detalle de una partida (recibe solo el id)
class DetalleScreen extends StatefulWidget {
  const DetalleScreen({super.key, required this.partidaId});

  final int partidaId;

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final _dao = PartidaDao();
  late Future<Partida?> _future;
  bool _existe = false;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  // Carga la partida de la BD
  Future<Partida?> _cargar() async {
    final partida = await _dao.obtenerPorId(widget.partidaId);
    if (mounted) setState(() => _existe = partida != null);
    return partida;
  }

  // Elimina y devuelve true a la pantalla anterior
  Future<void> _eliminar() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Eliminar partida',
      mensaje: 'No se podrá recuperar.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
      icono: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    try {
      await _dao.eliminar(widget.partidaId);
      if (mounted) Navigator.pop(context, true);
    } on DatosException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partida #${widget.partidaId}'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _existe ? _eliminar : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: AsyncDataView<Partida?>(
        future: _future,
        onReintentar: () => setState(() => _future = _cargar()),
        builder: (context, partida) {
          if (partida == null) {
            return const EmptyStateView(
              icono: Icons.search_off,
              mensaje: 'Esta partida ya no existe',
            );
          }
          return _contenido(partida);
        },
      ),
    );
  }

  // Tarjetas con los datos
  Widget _contenido(Partida p) {
    final tarjetas = [
      StatCard(titulo: 'Jugador', valor: p.usuario ?? '-', icono: Icons.person_outline),
      StatCard(titulo: 'Puntuación', valor: '${p.puntuacion}', icono: Icons.star_outline),
      StatCard(titulo: 'Ficha máxima', valor: '${p.fichaMaxima}', icono: Icons.grid_view),
      StatCard(titulo: 'Movimientos', valor: '${p.movimientos}', icono: Icons.swipe),
      StatCard(
        titulo: 'Duración',
        valor: formatearDuracion(p.duracionSegundos),
        icono: Icons.timer_outlined,
      ),
      StatCard(
        titulo: 'Fecha',
        valor: formatearFecha(p.fecha),
        icono: Icons.calendar_today_outlined,
      ),
      StatCard(
        titulo: 'Tablero',
        valor: '${p.tamanoTablero}×${p.tamanoTablero}',
        icono: Icons.border_all,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth > 600 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(AppEspaciado.m),
          children: [
            Center(
              child: TileWidget(
                valor: p.fichaMaxima,
                lado: AppMedidas.fichaDetalle,
                esNueva: true,
              ),
            ),
            const SizedBox(height: AppEspaciado.l),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                mainAxisSpacing: AppEspaciado.s,
                crossAxisSpacing: AppEspaciado.s,
                mainAxisExtent: AppMedidas.altoStatCard,
              ),
              children: tarjetas,
            ),
          ],
        );
      },
    );
  }
}
