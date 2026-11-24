import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/juego_2048.dart';

// Tablero con solo la primera fila rellena
List<int> fila(List<int> primera) => [...primera, ...List.filled(12, 0)];

// Primera fila sin contar la ficha nueva
List<int> primeraFila(Juego2048 juego, ResultadoMovimiento r) {
  final t = [...juego.tablero];
  if (r.posicionNueva != null) t[r.posicionNueva!] = 0;
  return t.sublist(0, 4);
}

void main() {
  group('Juego2048', () {
    test('al iniciar hay dos fichas', () {
      final juego = Juego2048(random: Random(1))..iniciar();
      expect(juego.tablero.where((v) => v != 0).length, 2);
      expect(juego.puntuacion, 0);
    });

    test('mover a la izquierda fusiona y suma', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 2, 4, 0]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.izquierda);
      expect(r.movido, isTrue);
      expect(primeraFila(juego, r), [4, 4, 0, 0]);
      expect(juego.puntuacion, 4);
      expect(juego.movimientos, 1);
    });

    test('cada ficha solo se fusiona una vez: [2,2,2,2] -> [4,4,0,0]', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 2, 2, 2]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.izquierda);
      expect(primeraFila(juego, r), [4, 4, 0, 0]);
      expect(juego.puntuacion, 8);
    });

    test('mover a la derecha', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([4, 4, 8, 0]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.derecha);
      expect(primeraFila(juego, r), [0, 0, 8, 8]);
    });

    test('si nada se mueve no cuenta', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 4, 8, 16]),
        puntuacion: 0,
        movimientos: 0,
      );
      final r = juego.mover(Direccion.izquierda);
      expect(r.movido, isFalse);
      expect(juego.movimientos, 0);
    });

    test('detecta que no quedan movimientos', () {
      final juego = Juego2048.desdeEstado(
        tablero: const [
          2, 4, 2, 4,
          4, 2, 4, 2,
          2, 4, 2, 4,
          4, 2, 4, 2,
        ],
        puntuacion: 0,
        movimientos: 0,
      );
      expect(juego.terminado, isTrue);
    });
  });
}
