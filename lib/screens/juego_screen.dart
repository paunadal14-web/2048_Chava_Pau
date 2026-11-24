import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/juego_2048.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/board_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/controles_direccion.dart';
import '../widgets/score_card.dart';

enum _AccionFin { jugarDeNuevo, volverAlInicio }

// Pantalla de juego
class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key, this.continuar = false});

  final bool continuar;

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  Juego2048 _juego = Juego2048()..iniciar();
  ResultadoMovimiento _ultimoMovimiento = ResultadoMovimiento.sinCambios;
  Timer? _reloj;
  int _segundosJugados = 0;
  int _mejor = 0;
  bool _terminada = false;
  bool _mostrarDetalles = false;

  @override
  void initState() {
    super.initState();
    _arrancarReloj();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  // Cronómetro de la partida
  void _arrancarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundosJugados++);
    });
  }

  // Aplica un movimiento
  void _mover(Direccion direccion) {
    if (_terminada) return;
    final resultado = _juego.mover(direccion);
    if (!resultado.movido) return;
    setState(() {
      _ultimoMovimiento = resultado;
      _mejor = max(_mejor, _juego.puntuacion);
    });
    if (_juego.terminado) _terminarPartida();
  }

  // Empieza de cero
  void _empezarDeNuevo() {
    setState(() {
      _juego = Juego2048()..iniciar();
      _ultimoMovimiento = ResultadoMovimiento.sinCambios;
      _segundosJugados = 0;
      _terminada = false;
    });
    _arrancarReloj();
  }

  // Reiniciar con confirmación
  Future<void> _reiniciar() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Reiniciar partida',
      mensaje: 'Perderás el progreso actual.',
      textoConfirmar: 'Reiniciar',
      destructivo: true,
    );
    if (ok) _empezarDeNuevo();
  }

  // Fin: guarda en el historial y muestra el resultado
  Future<void> _terminarPartida() async {
    setState(() => _terminada = true);
    _reloj?.cancel();
    final opcion = await ConfirmDialog.elegir<_AccionFin>(
      context,
      titulo: 'Partida terminada',
      mensaje: 'Puntuación: ${_juego.puntuacion}\n'
          'Ficha máxima: ${_juego.fichaMaxima}',
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
    if (opcion == _AccionFin.jugarDeNuevo) _empezarDeNuevo();
    if (opcion == _AccionFin.volverAlInicio) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(
            tooltip: 'Reiniciar',
            onPressed: _reiniciar,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppEspaciado.m),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppEspaciado.s,
                children: [
                  ScoreCard(
                    etiqueta: 'Puntos',
                    valor: _juego.puntuacion,
                    onDoubleTap: () =>
                        setState(() => _mostrarDetalles = !_mostrarDetalles),
                  ),
                  ScoreCard(etiqueta: 'Mejor', valor: _mejor),
                ],
              ),
              const SizedBox(height: AppEspaciado.s),
              Text('${_juego.movimientos} movimientos · '
                  '${formatearDuracion(_segundosJugados)}'),
              if (_mostrarDetalles) Text('Ficha máxima: ${_juego.fichaMaxima}'),
              const SizedBox(height: AppEspaciado.m),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: AppMedidas.anchoMaxTablero),
                    child: BoardWidget(
                      tablero: _juego.tablero,
                      tamano: _juego.tamano,
                      onMover: _mover,
                      revision: _juego.movimientos,
                      fusiones: _ultimoMovimiento.fusiones,
                      posicionNueva: _ultimoMovimiento.posicionNueva,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppEspaciado.m),
              ControlesDireccion(onMover: _mover),
            ],
          ),
        ),
      ),
    );
  }
}
