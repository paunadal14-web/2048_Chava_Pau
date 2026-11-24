import 'dart:async';

import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';

enum _MenuPartida { verDetalle, eliminar }

// Historial de partidas con filtros
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const List<int> _fichasFiltro = [128, 256, 512, 1024, 2048];
  static const Duration _retrasoFiltro = Duration(milliseconds: 300);

  final _dao = PartidaDao();
  final _filtroJugadorCtrl = TextEditingController();
  Timer? _temporizadorFiltro;
  int? _fichaMinima;
  late Future<List<Partida>> _future;

  bool get _filtrando => _filtroJugadorCtrl.text.trim().isNotEmpty || _fichaMinima != null;

  @override
  void initState() {
    super.initState();
    _future = _consultar();
  }

  @override
  void dispose() {
    _temporizadorFiltro?.cancel();
    _filtroJugadorCtrl.dispose();
    super.dispose();
  }

  // Consulta con los filtros actuales
  Future<List<Partida>> _consultar() {
    return _dao.obtenerHistorial(
      jugador: _filtroJugadorCtrl.text,
      fichaMinima: _fichaMinima,
    );
  }

  void _recargar() => setState(() => _future = _consultar());

  // Para el RefreshIndicator
  Future<void> _refrescar() async {
    _recargar();
    try {
      await _future;
    } catch (_) {
      // El error ya lo muestra AsyncDataView
    }
  }

  // Espera un poco antes de filtrar
  void _onTextoCambiado(String _) {
    _temporizadorFiltro?.cancel();
    _temporizadorFiltro = Timer(_retrasoFiltro, _recargar);
  }

  // Abre el detalle y recarga si se eliminó
  Future<void> _abrirDetalle(Partida partida) async {
    final eliminada = await Navigator.pushNamed(
      context,
      AppRoutes.detalle,
      arguments: partida.id,
    );
    if (!mounted || eliminada != true) return;
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partida eliminada')),
    );
  }

  // Borra y ofrece deshacer
  Future<void> _borrarConDeshacer(Partida partida) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _dao.eliminar(partida.id!);
    } on DatosException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
      _recargar();
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Partida de ${partida.puntuacion} pts eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            try {
              await _dao.insertar(partida);
              if (mounted) _recargar();
            } on DatosException catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
            }
          },
        ),
      ));
  }

  // Menú de pulsación larga
  Future<void> _abrirMenuOpciones(Partida partida, List<Partida> lista) async {
    final accion = await showModalBottomSheet<_MenuPartida>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver detalle'),
              onTap: () => Navigator.pop(context, _MenuPartida.verDetalle),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar'),
              onTap: () => Navigator.pop(context, _MenuPartida.eliminar),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;

    switch (accion) {
      case _MenuPartida.verDetalle:
        await _abrirDetalle(partida);
      case _MenuPartida.eliminar:
        final ok = await ConfirmDialog.confirmar(
          context,
          titulo: 'Eliminar partida',
          mensaje: '¿Eliminar la partida de ${partida.puntuacion} puntos?',
          textoConfirmar: 'Eliminar',
          destructivo: true,
        );
        if (!ok || !mounted) return;
        setState(() => lista.remove(partida));
        await _borrarConDeshacer(partida);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          _filtros(),
          Expanded(
            child: AsyncDataView<List<Partida>>(
              future: _future,
              onReintentar: _recargar,
              builder: (context, partidas) => RefreshIndicator(
                onRefresh: _refrescar,
                child: partidas.isEmpty ? _vacio() : _lista(partidas),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filtros por jugador y ficha
  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspaciado.m, AppEspaciado.s, AppEspaciado.m, AppEspaciado.s),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _filtroJugadorCtrl,
              onChanged: _onTextoCambiado,
              onSubmitted: (_) => _recargar(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Jugador',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtroJugadorCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filtroJugadorCtrl.clear();
                          _recargar();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppEspaciado.s),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<int?>(
              value: _fichaMinima,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Ficha ≥',
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                for (final v in _fichasFiltro)
                  DropdownMenuItem<int?>(value: v, child: Text('$v')),
              ],
              onChanged: (v) {
                _fichaMinima = v;
                _recargar();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Lista con deslizar para borrar
  Widget _lista(List<Partida> partidas) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppEspaciado.l),
      itemCount: partidas.length,
      itemBuilder: (context, i) {
        final partida = partidas[i];
        return Dismissible(
          key: ValueKey('partida-${partida.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.l),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          onDismissed: (_) {
            setState(() => partidas.removeAt(i));
            _borrarConDeshacer(partida);
          },
          child: PartidaListItem(
            partida: partida,
            onTap: () => _abrirDetalle(partida),
            onLongPress: () => _abrirMenuOpciones(partida, partidas),
          ),
        );
      },
    );
  }

  // Vista vacía
  Widget _vacio() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: EmptyStateView(
            icono: _filtrando ? Icons.filter_alt_off : Icons.history,
            mensaje: _filtrando
                ? 'No hay partidas con esos filtros'
                : 'Aún no has terminado ninguna partida',
            detalle: _filtrando ? null : 'Cuando acabes una partida aparecerá aquí.',
          ),
        ),
      ),
    );
  }
}
