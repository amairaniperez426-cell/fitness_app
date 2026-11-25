import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_widgets.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _bio = BiometricService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrarConPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final usuario = await DbService.instancia.validarUsuario(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (usuario != null) {
      _mensaje('¡Bienvenido de nuevo, ${usuario['nombre']}!', exito: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _mensaje('Correo o contraseña incorrectos', exito: false);
    }
  }

  Future<void> _entrarConHuella() async {
    setState(() => _cargando = true);

    final hayBiometria = await _bio.disponible();
    if (!hayBiometria) {
      _mensaje('Este dispositivo no tiene huella registrada', exito: false);
      setState(() => _cargando = false);
      return;
    }

    final ok = await _bio.autenticar();
    if (!mounted) return;
    setState(() => _cargando = false);

    if (ok) {
      _mensaje('Acceso concedido', exito: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _mensaje('Huella no reconocida, intenta de nuevo', exito: false);
    }
  }

  void _mensaje(String texto, {required bool exito}) {
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
      body: AppBackground(
        imagePath: 'assets/images/running.jpg',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            Icons.fitness_center,
                            size: 56,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fitness Tracker Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Monitorea tu actividad física en tiempo real',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

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
                            return 'Ingresa tu correo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón Iniciar Sesión
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
                        text: 'INICIAR SESIÓN',
                        icon: Icons.login,
                        onPressed: _entrarConPassword,
                      ),
                      const SizedBox(height: 12),

                      // Botón Entrar con Huella
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _cargando ? null : _entrarConHuella,
                        icon: const Icon(
                          Icons.fingerprint,
                          color: AppTheme.primary,
                        ),
                        label: const Text('Acceso con Huella / PIN'),
                      ),
                      const SizedBox(height: 20),

                      // Ir a Registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Regístrate aquí',
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