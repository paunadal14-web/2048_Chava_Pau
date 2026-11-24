import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../data/partida_guardada_dao.dart';
import '../game/juego_2048.dart';
import '../models/partida.dart';
import '../models/partida_guardada.dart';
import '../models/usuario.dart';
import '../services/preferencias_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/board_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/controles_direccion.dart';
import '../widgets/score_card.dart';

enum _AccionSalir { guardar, descartar, cancelar }

enum _AccionFin { jugarDeNuevo, volverAlInicio }

// Pantalla de juego
class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key, this.continuar = false});

  final bool continuar;

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> with WidgetsBindingObserver {
  final _partidaDao = PartidaDao();
  final _guardadaDao = PartidaGuardadaDao();

  late PreferenciasService _prefs;
  late Usuario _usuario;

  Juego2048? _juego;
  ResultadoMovimiento _ultimoMovimiento = ResultadoMovimiento.sinCambios;
  Timer? _reloj;
  int _segundosJugados = 0;
  int _mejor = 0;
  bool _vibracion = true;
  bool _terminada = false;
  bool _aviso2048Mostrado = false;
  bool _mostrarDetalles = false;
  bool _inicializado = false;

  // Hay partida empezada sin terminar
  bool get _enCurso => _juego != null && !_terminada && _juego!.movimientos > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    final scope = AppScope.of(context);
    _prefs = scope.preferencias;
    _usuario = scope.sesion.usuario!;
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloj?.cancel();
    super.dispose();
  }

  // Guarda al pasar a segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pararReloj();
        _guardar();
      case AppLifecycleState.resumed:
        if (_juego != null && !_terminada) _arrancarReloj();
      case AppLifecycleState.inactive:
        break;
    }
  }

  // Carga récord, ajustes y partida guardada
  Future<void> _cargar() async {
    PartidaGuardada? guardada;
    try {
      _mejor = max(
        await _prefs.leerMejorPuntuacion(),
        await _partidaDao.obtenerMejorPuntuacion(),
      );
      _vibracion = await _prefs.leerVibracion();
      if (widget.continuar) {
        guardada = await _guardadaDao.obtener(_usuario.id!);
      }
    } on DatosException catch (e) {
      _aviso(e.mensaje);
    }
    if (!mounted) return;

    final g = guardada;
    setState(() {
      _juego = g == null
          ? (Juego2048()..iniciar())
          : Juego2048.desdeEstado(
              tablero: g.tablero,
              puntuacion: g.puntuacion,
              movimientos: g.movimientos,
            );
      _segundosJugados = g?.segundosTranscurridos ?? 0;
      _aviso2048Mostrado = _juego!.haGanado;
    });
    _arrancarReloj();
    if (g != null) _aviso('Partida cargada');
  }

  // Guarda la partida en curso
  Future<bool> _guardar({bool avisar = false}) async {
    final juego = _juego;
    if (juego == null || !_enCurso) return false;
    try {
      await _guardadaDao.guardar(PartidaGuardada(
        usuarioId: _usuario.id!,
        tablero: juego.tablero,
        puntuacion: juego.puntuacion,
        movimientos: juego.movimientos,
        segundosTranscurridos: _segundosJugados,
      ));
      if (avisar) _aviso('Partida guardada');
      return true;
    } on DatosException catch (e) {
      _aviso(e.mensaje);
      return false;
    }
  }

  // Cronómetro de la partida
  void _arrancarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundosJugados++);
    });
  }

  void _pararReloj() {
    _reloj?.cancel();
    _reloj = null;
  }

  // Aplica un movimiento
  void _mover(Direccion direccion) {
    final juego = _juego;
    if (juego == null || _terminada) return;

    final resultado = juego.mover(direccion);
    if (!resultado.movido) return;

    if (_vibracion && resultado.fusiones.isNotEmpty) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _ultimoMovimiento = resultado;
      _mejor = max(_mejor, juego.puntuacion);
    });

    if (!_aviso2048Mostrado && juego.haGanado) {
      _aviso2048Mostrado = true;
      _aviso('¡Conseguido ${Juego2048.objetivo}! Puedes continuar.');
    }
    if (juego.terminado) _terminarPartida();
  }

  // Empieza de cero
  void _empezarDeNuevo() {
    setState(() {
      _juego = Juego2048()..iniciar();
      _ultimoMovimiento = ResultadoMovimiento.sinCambios;
      _segundosJugados = 0;
      _terminada = false;
      _aviso2048Mostrado = false;
    });
    _arrancarReloj();
  }

  // Reiniciar con confirmación
  Future<void> _reiniciar() async {
    if (_enCurso) {
      final ok = await ConfirmDialog.confirmar(
        context,
        titulo: 'Reiniciar partida',
        mensaje: 'Perderás el progreso actual.',
        textoConfirmar: 'Reiniciar',
        destructivo: true,
        icono: Icons.restart_alt,
      );
      if (!ok) return;
    }
    try {
      await _guardadaDao.eliminar();
    } on DatosException catch (e) {
      _aviso(e.mensaje);
    }
    _empezarDeNuevo();
  }

  // Fin: guarda en el historial y muestra el resultado
  Future<void> _terminarPartida() async {
    final juego = _juego!;
    setState(() => _terminada = true);
    _pararReloj();

    var record = false;
    try {
      await _partidaDao.finalizarPartida(Partida(
        usuarioId: _usuario.id!,
        puntuacion: juego.puntuacion,
        fichaMaxima: juego.fichaMaxima,
        movimientos: juego.movimientos,
        duracionSegundos: _segundosJugados,
        fecha: DateTime.now(),
      ));
      record = await _prefs.actualizarMejorPuntuacion(juego.puntuacion);
      _aviso('Partida añadida al historial');
    } on DatosException catch (e) {
      _aviso(e.mensaje);
    }
    if (!mounted) return;

    final opcion = await ConfirmDialog.elegir<_AccionFin>(
      context,
      titulo: record ? '¡Nuevo récord!' : 'Partida terminada',
      icono: record ? Icons.emoji_events : Icons.flag,
      mensaje: 'Puntuación: ${juego.puntuacion}\n'
          'Ficha máxima: ${juego.fichaMaxima}\n'
          'Movimientos: ${juego.movimientos}\n'
          'Duración: ${formatearDuracion(_segundosJugados)}',
      opciones: const [
        OpcionDialogo(texto: 'Volver al inicio', valor: _AccionFin.volverAlInicio),
        OpcionDialogo(
          texto: 'Jugar de nuevo',
          valor: _AccionFin.jugarDeNuevo,
          principal: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (opcion) {
      case _AccionFin.jugarDeNuevo:
        _empezarDeNuevo();
      case _AccionFin.volverAlInicio:
        Navigator.pop(context, true);
      case null:
        break;
    }
  }

  // Salir: guardar, descartar o cancelar
  Future<void> _confirmarSalida() async {
    final opcion = await ConfirmDialog.elegir<_AccionSalir>(
      context,
      titulo: '¿Salir de la partida?',
      mensaje: 'La partida no ha terminado. ¿Qué quieres hacer?',
      icono: Icons.exit_to_app,
      opciones: const [
        OpcionDialogo(texto: 'Cancelar', valor: _AccionSalir.cancelar),
        OpcionDialogo(
          texto: 'Salir sin guardar',
          valor: _AccionSalir.descartar,
          destructiva: true,
        ),
        OpcionDialogo(
          texto: 'Guardar y salir',
          valor: _AccionSalir.guardar,
          principal: true,
        ),
      ],
    );
    if (!mounted) return;

    switch (opcion) {
      case _AccionSalir.guardar:
        if (!await _guardar(avisar: true)) return;
      case _AccionSalir.descartar:
        try {
          await _guardadaDao.eliminar();
        } on DatosException catch (e) {
          _aviso(e.mensaje);
        }
      case _AccionSalir.cancelar:
      case null:
        return;
    }
    _pararReloj();
    if (mounted) Navigator.pop(context, true);
  }

  // Muestra un SnackBar
  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enCurso,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('2048'),
          actions: [
            IconButton(
              tooltip: 'Guardar partida',
              onPressed: _enCurso ? () => _guardar(avisar: true) : null,
              icon: const Icon(Icons.save_outlined),
            ),
            IconButton(
              tooltip: 'Reiniciar',
              onPressed: _juego == null ? null : _reiniciar,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        body: SafeArea(
          child: _juego == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(AppEspaciado.m),
                  child: MediaQuery.orientationOf(context) == Orientation.landscape
                      ? _layoutHorizontal()
                      : _layoutVertical(),
                ),
        ),
      ),
    );
  }

  // Diseño en vertical
  Widget _layoutVertical() {
    return Column(
      children: [
        _cabeceraPuntos(),
        const SizedBox(height: AppEspaciado.s),
        _chipsInfo(),
        _panelDetalles(),
        const SizedBox(height: AppEspaciado.m),
        Expanded(child: Center(child: _tablero())),
        const SizedBox(height: AppEspaciado.m),
        ControlesDireccion(onMover: _mover),
      ],
    );
  }

  // Diseño en horizontal
  Widget _layoutHorizontal() {
    return Row(
      children: [
        Expanded(child: Center(child: _tablero())),
        const SizedBox(width: AppEspaciado.l),
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _cabeceraPuntos(),
                const SizedBox(height: AppEspaciado.s),
                _chipsInfo(),
                _panelDetalles(),
                const SizedBox(height: AppEspaciado.m),
                ControlesDireccion(onMover: _mover),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tablero() {
    final juego = _juego!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppMedidas.anchoMaxTablero),
      child: BoardWidget(
        tablero: juego.tablero,
        tamano: juego.tamano,
        onMover: _mover,
        revision: juego.movimientos,
        fusiones: _ultimoMovimiento.fusiones,
        posicionNueva: _ultimoMovimiento.posicionNueva,
      ),
    );
  }

  // Doble toque en Puntos muestra los detalles
  Widget _cabeceraPuntos() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppEspaciado.s,
      runSpacing: AppEspaciado.s,
      children: [
        ScoreCard(
          etiqueta: 'Puntos',
          valor: _juego!.puntuacion,
          onDoubleTap: () => setState(() => _mostrarDetalles = !_mostrarDetalles),
        ),
        ScoreCard(etiqueta: 'Mejor', valor: _mejor),
      ],
    );
  }

  Widget _chipsInfo() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppEspaciado.s,
      children: [
        Chip(
          avatar: const Icon(Icons.swipe, size: 18),
          label: Text('Movimientos: ${_juego!.movimientos}'),
        ),
        Chip(
          avatar: const Icon(Icons.timer_outlined, size: 18),
          label: Text(formatearDuracion(_segundosJugados)),
        ),
      ],
    );
  }

  // Panel de detalles
  Widget _panelDetalles() {
    final juego = _juego!;
    return AnimatedSize(
      duration: AppTiempos.aparicion,
      child: !_mostrarDetalles
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppEspaciado.s),
              child: Text(
                'Jugador: ${_usuario.usuario} · '
                'Ficha máxima: ${juego.fichaMaxima} · '
                'Quedan ${max(0, Juego2048.objetivo - juego.fichaMaxima)} para ${Juego2048.objetivo}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
    );
  }
}
