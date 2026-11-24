// Número con dos cifras
String _pad2(int v) => v.toString().padLeft(2, '0');

// Segundos -> mm:ss o h:mm:ss
String formatearDuracion(int segundos) {
  final h = segundos ~/ 3600;
  final m = (segundos % 3600) ~/ 60;
  final s = segundos % 60;
  return h > 0 ? '$h:${_pad2(m)}:${_pad2(s)}' : '${_pad2(m)}:${_pad2(s)}';
}

// Fecha -> dd/mm/aaaa hh:mm
String formatearFecha(DateTime fecha) {
  final l = fecha.toLocal();
  return '${_pad2(l.day)}/${_pad2(l.month)}/${l.year} ${_pad2(l.hour)}:${_pad2(l.minute)}';
}
