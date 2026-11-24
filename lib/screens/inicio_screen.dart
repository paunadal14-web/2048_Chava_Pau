import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../data/partida_guardada_dao.dart';
import '../models/partida_guardada.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/score_card.dart';

// Índices de las pestañas
abstract final class TabsInicio {
  static const int historial = 1;
  static const int ranking = 2;
  static const int ajustes = 3;
}

// Datos que necesita la pantalla de inicio
class _ResumenInicio {
  const _ResumenInicio({
    required this.mejorGlobal,
    required this.mejorPropia,
    required this.guardada,
  });

  final int mejorGlobal;
  final int mejorPropia;
  final PartidaGuardada? guardada;
}

// Pantalla de inicio
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.onNavegar});

  final ValueChanged<int>? onNavegar;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _partidaDao = PartidaDao();
  final _guardadaDao = PartidaGuardadaDao();
  Future<_ResumenInicio>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _cargar();
  }

  // Mejores puntuaciones y partida guardada
  Future<_ResumenInicio> _cargar() async {
    final scope = AppScope.of(context);
    final usuarioId = scope.sesion.usuario!.id!;
    final mejorPrefs = await scope.preferencias.leerMejorPuntuacion();
    final mejorBD = await _partidaDao.obtenerMejorPuntuacion();
    return _ResumenInicio(
      mejorGlobal: mejorPrefs > mejorBD ? mejorPrefs : mejorBD,
      mejorPropia: await _partidaDao.obtenerMejorPuntuacion(usuarioId: usuarioId),
      guardada: await _guardadaDao.obtener(usuarioId),
    );
  }

  void _recargar() => setState(() => _future = _cargar());

  // Nueva partida o continuar
  Future<void> _jugar(_ResumenInicio datos, {required bool continuar}) async {
    if (!continuar && datos.guardada != null) {
      final ok = await ConfirmDialog.confirmar(
        context,
        titulo: 'Nueva partida',
        mensaje: 'Hay una partida guardada. Si empiezas otra se perderá.',
        textoConfirmar: 'Empezar nueva',
        destructivo: true,
      );
      if (!ok) return;
      try {
        await _guardadaDao.eliminar();
      } on DatosException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.mensaje)));
        }
        return;
      }
    }
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.juego, arguments: continuar);
    if (mounted) _recargar();
  }

  // Cerrar sesión
  Future<void> _cerrarSesion() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar la sesión?',
      textoConfirmar: 'Salir',
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).sesion.cerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).sesion.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AsyncDataView<_ResumenInicio>(
        future: _future!,
        onReintentar: _recargar,
        builder: (context, datos) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspaciado.l),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppMedidas.anchoMaxFormulario),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('2048',
                      textAlign: TextAlign.center,
                      style: AppEstilosTexto.tituloJuego(context)),
                  Text(
                    '¡A jugar, ${usuario?.usuario ?? 'jugador'}!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppEspaciado.l),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppEspaciado.s,
                    runSpacing: AppEspaciado.s,
                    children: [
                      ScoreCard(etiqueta: 'Mejor', valor: datos.mejorGlobal),
                      ScoreCard(etiqueta: 'Tu récord', valor: datos.mejorPropia),
                    ],
                  ),
                  const SizedBox(height: AppEspaciado.xl),
                  // Solo si hay partida guardada
                  if (datos.guardada != null) ...[
                    FilledButton.icon(
                      onPressed: () => _jugar(datos, continuar: true),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Continuar partida (${datos.guardada!.puntuacion} pts · '
                        '${formatearDuracion(datos.guardada!.segundosTranscurridos)})',
                      ),
                    ),
                    const SizedBox(height: AppEspaciado.s),
                    OutlinedButton.icon(
                      onPressed: () => _jugar(datos, continuar: false),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva partida'),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: () => _jugar(datos, continuar: false),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva partida'),
                    ),
                  const SizedBox(height: AppEspaciado.l),
                  _BotonAcceso(
                    icono: Icons.history,
                    texto: 'Historial',
                    onPressed: () => widget.onNavegar?.call(TabsInicio.historial),
                  ),
                  _BotonAcceso(
                    icono: Icons.leaderboard_outlined,
                    texto: 'Ranking y estadísticas',
                    onPressed: () => widget.onNavegar?.call(TabsInicio.ranking),
                  ),
                  _BotonAcceso(
                    icono: Icons.settings_outlined,
                    texto: 'Ajustes',
                    onPressed: () => widget.onNavegar?.call(TabsInicio.ajustes),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botón de acceso a otra sección
class _BotonAcceso extends StatelessWidget {
  const _BotonAcceso({
    required this.icono,
    required this.texto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.s),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono),
        label: Text(texto),
      ),
    );
  }
}
