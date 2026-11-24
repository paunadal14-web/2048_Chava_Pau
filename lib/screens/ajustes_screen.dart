import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/paleta_fichas.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/tile_widget.dart';

// Pantalla de ajustes
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  static const List<int> _valoresEjemplo = [2, 8, 64, 512, 2048];

  final _dao = PartidaDao();
  bool? _vibracion;

  // Lee la preferencia de vibración
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vibracion == null) {
      AppScope.of(context).preferencias.leerVibracion().then((v) {
        if (mounted) setState(() => _vibracion = v);
      });
    }
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Borra todo el historial con confirmación
  Future<void> _borrarHistorial() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Borrar todo el historial',
      mensaje: 'Se eliminarán todas las partidas terminadas de todos los '
          'jugadores. Esta acción no se puede deshacer.',
      textoConfirmar: 'Borrar todo',
      destructivo: true,
      icono: Icons.delete_forever_outlined,
    );
    if (!ok || !mounted) return;
    final preferencias = AppScope.of(context).preferencias;
    try {
      final borradas = await _dao.eliminarTodo();
      await preferencias.reiniciarMejorPuntuacion();
      _aviso('Historial borrado ($borradas partidas)');
    } on DatosException catch (e) {
      _aviso(e.mensaje);
    }
  }

  // Cierra sesión y vuelve al login
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
    final scope = AppScope.of(context);
    final tema = scope.tema;
    final usuario = scope.sesion.usuario;
    final estilos = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: tema,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppEspaciado.s),
          children: [
            // Modo de tema
            const _TituloSeccion('Apariencia'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.m),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Claro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Oscuro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_suggest_outlined),
                    label: Text('Sistema'),
                  ),
                ],
                selected: {tema.modo},
                onSelectionChanged: (seleccion) => tema.cambiarModo(seleccion.first),
              ),
            ),
            // Paleta de colores
            const _TituloSeccion('Color de las fichas'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.m),
              child: Wrap(
                spacing: AppEspaciado.s,
                runSpacing: AppEspaciado.s,
                children: [
                  for (final paleta in PaletaFichas.values)
                    ChoiceChip(
                      label: Text(paleta.etiqueta),
                      avatar: _CirculoPaleta(paleta),
                      showCheckmark: false,
                      selected: tema.paleta == paleta,
                      onSelected: (_) => tema.cambiarPaleta(paleta),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppEspaciado.m),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppEspaciado.s,
              children: [
                for (final v in _valoresEjemplo)
                  TileWidget(valor: v, lado: AppMedidas.fichaMiniatura),
              ],
            ),
            const _TituloSeccion('Juego'),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibrar al juntar fichas'),
              value: _vibracion ?? true,
              onChanged: _vibracion == null
                  ? null
                  : (v) {
                      setState(() => _vibracion = v);
                      scope.preferencias.guardarVibracion(v);
                    },
            ),
            const _TituloSeccion('Datos'),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: estilos.colorScheme.error),
              title: Text('Borrar todo el historial',
                  style: TextStyle(color: estilos.colorScheme.error)),
              subtitle: const Text('Se pedirá confirmación'),
              onTap: _borrarHistorial,
            ),
            const _TituloSeccion('Cuenta'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(usuario?.usuario ?? '-'),
              subtitle: Text(usuario?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
    );
  }
}

// Título de sección
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspaciado.m, AppEspaciado.l, AppEspaciado.m, AppEspaciado.s),
      child: Text(
        texto,
        style: estilos.textTheme.titleSmall
            ?.copyWith(color: estilos.colorScheme.primary),
      ),
    );
  }
}

// Círculo con los colores de una paleta
class _CirculoPaleta extends StatelessWidget {
  const _CirculoPaleta(this.paleta);

  final PaletaFichas paleta;

  @override
  Widget build(BuildContext context) {
    final colores = AppTheme.coloresPaleta(paleta);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [colores[2], colores[5], colores[10], colores[2]]),
      ),
    );
  }
}
