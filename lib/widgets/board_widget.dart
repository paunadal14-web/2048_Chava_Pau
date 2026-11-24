import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/juego_2048.dart';
import '../theme/app_theme.dart';
import 'tile_widget.dart';

// Tablero: dibuja las fichas y detecta gestos y teclas
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.tablero,
    required this.tamano,
    required this.onMover,
    this.revision = 0,
    this.fusiones = const {},
    this.posicionNueva,
  });

  final List<int> tablero;
  final int tamano;
  final ValueChanged<Direccion> onMover;

  final int revision;
  final Set<int> fusiones;
  final int? posicionNueva;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final FocusNode _focusTablero = FocusNode(debugLabel: 'tablero');
  Offset _arrastre = Offset.zero;

  // Flechas y WASD
  static final Map<LogicalKeyboardKey, Direccion> _mapaTeclas = {
    LogicalKeyboardKey.arrowUp: Direccion.arriba,
    LogicalKeyboardKey.arrowDown: Direccion.abajo,
    LogicalKeyboardKey.arrowLeft: Direccion.izquierda,
    LogicalKeyboardKey.arrowRight: Direccion.derecha,
    LogicalKeyboardKey.keyW: Direccion.arriba,
    LogicalKeyboardKey.keyS: Direccion.abajo,
    LogicalKeyboardKey.keyA: Direccion.izquierda,
    LogicalKeyboardKey.keyD: Direccion.derecha,
  };

  @override
  void dispose() {
    _focusTablero.dispose();
    super.dispose();
  }

  // Acumula el arrastre
  void _onPanStart(DragStartDetails _) => _arrastre = Offset.zero;

  void _onPanUpdate(DragUpdateDetails d) => _arrastre += d.delta;

  // Al soltar decide la dirección
  void _onPanEnd(DragEndDetails _) {
    final dx = _arrastre.dx;
    final dy = _arrastre.dy;
    _arrastre = Offset.zero;

    if (dx.abs() < AppMedidas.umbralSwipe && dy.abs() < AppMedidas.umbralSwipe) {
      return;
    }
    final direccion = dx.abs() > dy.abs()
        ? (dx > 0 ? Direccion.derecha : Direccion.izquierda)
        : (dy > 0 ? Direccion.abajo : Direccion.arriba);
    widget.onMover(direccion);
  }

  // Teclado
  KeyEventResult _onKey(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent && evento is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direccion = _mapaTeclas[evento.logicalKey];
    if (direccion == null) return KeyEventResult.ignored;
    widget.onMover(direccion);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final fichas = ColoresFichasTheme.of(context);
    final n = widget.tamano;
    const sep = AppMedidas.separacionCeldas;

    return Focus(
      focusNode: _focusTablero,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusTablero.requestFocus,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ladoCelda = (constraints.maxWidth - sep * (n + 1)) / n;
              return Container(
                padding: const EdgeInsets.all(sep),
                decoration: BoxDecoration(
                  color: fichas.fondoTablero,
                  borderRadius: BorderRadius.circular(AppMedidas.radioTablero),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var f = 0; f < n; f++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var c = 0; c < n; c++) _construirCelda(f * n + c, ladoCelda),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Una casilla del tablero
  Widget _construirCelda(int indice, double lado) {
    final esNueva = indice == widget.posicionNueva;
    final esFusion = widget.fusiones.contains(indice);
    final animada = esNueva || esFusion;
    return TileWidget(
      key: ValueKey('celda-$indice-${animada ? widget.revision : 0}'),
      valor: widget.tablero[indice],
      lado: lado,
      esNueva: esNueva,
      esFusion: esFusion,
    );
  }
}
