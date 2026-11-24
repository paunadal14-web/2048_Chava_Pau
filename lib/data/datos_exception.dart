// Error de la capa de datos con mensaje legible
class DatosException implements Exception {
  const DatosException(this.mensaje, [this.causa]);

  final String mensaje;
  final Object? causa;

  @override
  String toString() => 'DatosException: $mensaje${causa != null ? ' ($causa)' : ''}';
}
