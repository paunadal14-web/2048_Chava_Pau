import 'package:flutter/material.dart';

import '../data/partida_dao.dart';
import '../models/estadisticas.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';
import '../widgets/stat_card.dart';

// Datos de la pantalla de ranking
class _ResumenRanking {
  const _ResumenRanking(this.globales, this.top10, this.porJugador);

  final EstadisticasGlobales globales;
  final List<Partida> top10;
  final List<EstadisticaJugador> porJugador;
}

// Ranking y estadísticas
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _dao = PartidaDao();
  late Future<_ResumenRanking> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  // Lanza las tres consultas
  Future<_ResumenRanking> _cargar() async {
    return _ResumenRanking(
      await _dao.obtenerEstadisticasGlobales(),
      await _dao.obtenerTop10(),
      await _dao.obtenerEstadisticasPorJugador(),
    );
  }

  void _recargar() => setState(() => _future = _cargar());

  Future<void> _refrescar() async {
    _recargar();
    try {
      await _future;
    } catch (_) {
      // El error ya lo muestra AsyncDataView
    }
  }

  Future<void> _abrirDetalle(Partida partida) async {
    final eliminada = await Navigator.pushNamed(
      context,
      AppRoutes.detalle,
      arguments: partida.id,
    );
    if (mounted && eliminada == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking y estadísticas')),
      body: AsyncDataView<_ResumenRanking>(
        future: _future,
        onReintentar: _recargar,
        builder: (context, datos) => RefreshIndicator(
          onRefresh: _refrescar,
          child: datos.globales.partidasJugadas == 0
              ? _vacio()
              : _contenido(datos),
        ),
      ),
    );
  }

  // Estadísticas, top 10 y por jugador
  Widget _contenido(_ResumenRanking datos) {
    final g = datos.globales;
    final tema = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth > 600 ? 3 : 2;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppEspaciado.l),
          children: [
            const _Titulo('Estadísticas globales'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.m),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisSpacing: AppEspaciado.s,
                  crossAxisSpacing: AppEspaciado.s,
                  mainAxisExtent: AppMedidas.altoStatCard,
                ),
                children: [
                  StatCard(
                    titulo: 'Partidas',
                    valor: '${g.partidasJugadas}',
                    icono: Icons.sports_esports_outlined,
                  ),
                  StatCard(
                    titulo: 'Máxima',
                    valor: '${g.puntuacionMaxima}',
                    icono: Icons.emoji_events_outlined,
                  ),
                  StatCard(
                    titulo: 'Media',
                    valor: g.puntuacionMedia.toStringAsFixed(0),
                    icono: Icons.functions,
                  ),
                  StatCard(
                    titulo: 'Ficha máx.',
                    valor: '${g.fichaMaxima}',
                    icono: Icons.grid_view,
                  ),
                  StatCard(
                    titulo: 'Tiempo total',
                    valor: formatearDuracion(g.tiempoTotalSegundos),
                    icono: Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            const _Titulo('Top 10'),
            for (var i = 0; i < datos.top10.length; i++)
              PartidaListItem(
                partida: datos.top10[i],
                posicion: i + 1,
                onTap: () => _abrirDetalle(datos.top10[i]),
              ),
            const _Titulo('Por jugador'),
            Card(
              child: Column(
                children: [
                  for (final j in datos.porJugador)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tema.colorScheme.secondaryContainer,
                        child: Text(
                          j.usuario.characters.first.toUpperCase(),
                          style: TextStyle(
                              color: tema.colorScheme.onSecondaryContainer),
                        ),
                      ),
                      title: Text(j.usuario),
                      subtitle: Text(
                          '${j.partidas} ${j.partidas == 1 ? 'partida' : 'partidas'}'),
                      trailing: Text(
                        '${j.mejorPuntuacion} pts',
                        style: tema.textTheme.titleMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _vacio() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const EmptyStateView(
            icono: Icons.leaderboard_outlined,
            mensaje: 'El ranking está vacío',
            detalle: 'Termina una partida para ver estadísticas.',
          ),
        ),
      ),
    );
  }
}

// Título de sección
class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspaciado.m, AppEspaciado.l, AppEspaciado.m, AppEspaciado.s),
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
