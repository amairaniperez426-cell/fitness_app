import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // ¿El dispositivo tiene algún método de seguridad (huella, rostro o PIN)?
  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // Acepta huella, rostro o, como respaldo, el PIN/patrón del celular
  Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Valida tu identidad para entrar a Fitness App',
      );
    } catch (_) {
      return false;
    }
  }
}