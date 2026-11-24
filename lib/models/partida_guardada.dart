import 'dart:convert';

// Partida en curso guardada
class PartidaGuardada {
  const PartidaGuardada({
    required this.usuarioId,
    required this.tablero,
    required this.puntuacion,
    required this.movimientos,
    required this.segundosTranscurridos,
  });

  // Solo hay una fila, siempre con id 1
  static const int idUnico = 1;

  final int usuarioId;

  // Valores del tablero (se guardan en JSON)
  final List<int> tablero;
  final int puntuacion;
  final int movimientos;
  final int segundosTranscurridos;

  // Objeto -> fila de la BD
  Map<String, Object?> toMap() {
    return {
      'id': idUnico,
      'usuario_id': usuarioId,
      'tablero': jsonEncode(tablero),
      'puntuacion': puntuacion,
      'movimientos': movimientos,
      'segundos_transcurridos': segundosTranscurridos,
    };
  }

  // Fila de la BD -> objeto
  factory PartidaGuardada.fromMap(Map<String, Object?> map) {
    final lista = jsonDecode(map['tablero'] as String) as List<dynamic>;
    return PartidaGuardada(
      usuarioId: map['usuario_id'] as int,
      tablero: lista.map((e) => e as int).toList(),
      puntuacion: map['puntuacion'] as int,
      movimientos: map['movimientos'] as int,
      segundosTranscurridos: map['segundos_transcurridos'] as int,
    );
  }
}
