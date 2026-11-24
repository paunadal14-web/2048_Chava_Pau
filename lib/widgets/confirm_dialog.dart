import 'package:flutter/material.dart';

// Botón del diálogo
class OpcionDialogo<T> {
  const OpcionDialogo({
    required this.texto,
    required this.valor,
    this.principal = false,
    this.destructiva = false,
  });

  final String texto;
  final T valor;
  final bool principal;
  final bool destructiva;
}

// Diálogo genérico de confirmación
class ConfirmDialog<T> extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.opciones,
    this.icono,
  });

  final String titulo;
  final String mensaje;
  final List<OpcionDialogo<T>> opciones;
  final IconData? icono;

  // Atajo para sí/no
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Aceptar',
    String textoCancelar = 'Cancelar',
    bool destructivo = false,
    IconData? icono,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog<bool>(
        titulo: titulo,
        mensaje: mensaje,
        icono: icono,
        opciones: [
          OpcionDialogo(texto: textoCancelar, valor: false),
          OpcionDialogo(
            texto: textoConfirmar,
            valor: true,
            principal: true,
            destructiva: destructivo,
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  // Diálogo con varias opciones
  static Future<R?> elegir<R>(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required List<OpcionDialogo<R>> opciones,
    IconData? icono,
  }) {
    return showDialog<R>(
      context: context,
      builder: (_) => ConfirmDialog<R>(
        titulo: titulo,
        mensaje: mensaje,
        opciones: opciones,
        icono: icono,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: icono == null ? null : Icon(icono),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        for (final opcion in opciones)
          if (opcion.principal)
            FilledButton(
              style: opcion.destructiva
                  ? FilledButton.styleFrom(
                      backgroundColor: esquema.error,
                      foregroundColor: esquema.onError,
                      minimumSize: Size.zero,
                    )
                  : FilledButton.styleFrom(minimumSize: Size.zero),
              onPressed: () => Navigator.pop(context, opcion.valor),
              child: Text(opcion.texto),
            )
          else
            TextButton(
              style: opcion.destructiva
                  ? TextButton.styleFrom(foregroundColor: esquema.error)
                  : null,
              onPressed: () => Navigator.pop(context, opcion.valor),
              child: Text(opcion.texto),
            ),
      ],
    );
  }
}
