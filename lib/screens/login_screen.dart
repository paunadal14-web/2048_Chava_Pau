import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

// Pantalla de login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioEmailCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultarPass = true;

  // Rellena el último jugador
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioEmailCtrl.text.isEmpty) {
      AppScope.of(context).preferencias.leerUltimoJugador().then((nombre) {
        if (mounted && nombre != null && _usuarioEmailCtrl.text.isEmpty) {
          _usuarioEmailCtrl.text = nombre;
        }
      });
    }
  }

  @override
  void dispose() {
    _usuarioEmailCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  // Valida y entra
  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AppScope.of(context)
          .sesion
          .iniciarSesion(_usuarioEmailCtrl.text, _contrasenaCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspaciado.l),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppMedidas.anchoMaxFormulario),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('2048',
                        textAlign: TextAlign.center,
                        style: AppEstilosTexto.tituloJuego(context)),
                    const SizedBox(height: AppEspaciado.s),
                    Text('Entra con tu cuenta para jugar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppEspaciado.xl),
                    TextFormField(
                      controller: _usuarioEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario o email',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: AppEspaciado.m),
                    TextFormField(
                      controller: _contrasenaCtrl,
                      obscureText: _ocultarPass,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultarPass ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultarPass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    const SizedBox(height: AppEspaciado.l),
                    FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: AppEspaciado.s),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.pushNamed(context, AppRoutes.registro),
                      child: const Text('¿Aún no tienes cuenta? Crea una'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
