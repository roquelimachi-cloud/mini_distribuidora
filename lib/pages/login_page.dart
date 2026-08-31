import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Future<void> Function(BuildContext context)
      onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _usuarioController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _ocultarPassword = true;
  bool _ingresando = false;

  String? _error;

 @override
void initState() {
  super.initState();
}

  Future<void> _verificarSesion() async {
    if (_authService.estaAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        widget.onLoginSuccess(context);
      });
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _ingresar() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _ingresando = true;
      _error = null;
    });

    try {
      await _authService.iniciarSesion(
        usuario: _usuarioController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      await widget.onLoginSuccess(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _mensajeError(e);
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _ingresando = false;
      });
    }
  }

  String _mensajeError(Object error) {
    final texto = error.toString();

    if (texto.contains('Invalid login credentials')) {
      return 'Usuario o contraseña incorrectos.';
    }

    if (texto.contains('Email not confirmed')) {
      return 'El correo del usuario todavía no está confirmado.';
    }

    if (texto.contains('Usuario o contraseña')) {
      return 'Usuario o contraseña incorrectos.';
    }

    if (texto.contains('desactivado')) {
      return texto;
    }

    return texto.replaceFirst(
      'Exception: ',
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ------------------------------------------------
                      // ICONO
                      // ------------------------------------------------

                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront,
                          size: 42,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Mini Distribuidora MR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ------------------------------------------------
                      // USUARIO
                      // ------------------------------------------------

                      TextField(
                        controller: _usuarioController,
                        textInputAction:
                            TextInputAction.next,
                        textCapitalization:
                            TextCapitalization.none,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          hintText: 'mroque',
                          prefixIcon:
                              Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          FocusScope.of(context)
                              .nextFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // CONTRASEÑA
                      // ------------------------------------------------

                      TextField(
                        controller:
                            _passwordController,
                        obscureText: _ocultarPassword,
                        textInputAction:
                            TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            tooltip:
                                _ocultarPassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                            onPressed: () {
                              setState(() {
                                _ocultarPassword =
                                    !_ocultarPassword;
                              });
                            },
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                          border:
                              const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          if (!_ingresando) {
                            _ingresar();
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------

                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style:
                                      const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ------------------------------------------------
                      // BOTÓN
                      // ------------------------------------------------

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed:
                              _ingresando
                                  ? null
                                  : _ingresar,
                          icon: _ingresando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.login,
                                ),
                          label: Text(
                            _ingresando
                                ? 'Ingresando...'
                                : 'Ingresar',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Acceso seguro',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}