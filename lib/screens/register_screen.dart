import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_widgets.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _ocultarConfirmPass = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final exito = await DbService.instancia.registrarUsuario(
      _nombreCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito) {
      _notificar('Registro exitoso. Ahora inicia sesión', exito: true);
      Navigator.pop(context);
    } else {
      _notificar('El correo ya está registrado o fue inválido', exito: false);
    }
  }

  void _notificar(String texto, {required bool exito}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: exito ? Colors.teal.shade700 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icono, {Widget? sufijo}) {
    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icono, color: AppTheme.primary),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: borde(Colors.white38),
      focusedBorder: borde(AppTheme.primary, 2),
      errorBorder: borde(const Color(0xFFFF8A80)),
      focusedErrorBorder: borde(const Color(0xFFFF8A80), 2),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(git
        title: const Text('Crear Cuenta'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: AppBackground(
        imagePath: 'assets/images/walking.jpg',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            size: 50,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Registro de Usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea tu cuenta para guardar tu actividad física',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Nombre
                      TextFormField(
                        controller: _nombreCtrl,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.primary,
                        decoration: _decoracion(
                          'Nombre completo',
                          Icons.person_outline,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu nombre completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Correo
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.primary,
                        decoration: _decoracion(
                          'Correo electrónico',
                          Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu correo electrónico';
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v.trim())) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Contraseña
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _ocultarPass,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.primary,
                        decoration: _decoracion(
                          'Contraseña',
                          Icons.lock_outline,
                          sufijo: IconButton(
                            icon: Icon(
                              _ocultarPass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() => _ocultarPass = !_ocultarPass);
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (v.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirmar Contraseña
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _ocultarConfirmPass,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.primary,
                        decoration: _decoracion(
                          'Confirmar contraseña',
                          Icons.lock_reset,
                          sufijo: IconButton(
                            icon: Icon(
                              _ocultarConfirmPass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() =>
                              _ocultarConfirmPass = !_ocultarConfirmPass);
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (v != _passCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón Registrarse
                      _cargando
                          ? const SizedBox(
                        height: 56,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                          : GradientButton(
                        text: 'REGISTRARSE',
                        icon: Icons.check_circle_outline,
                        onPressed: _registrar,
                      ),
                      const SizedBox(height: 16),

                      // Enlace a Iniciar Sesión
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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