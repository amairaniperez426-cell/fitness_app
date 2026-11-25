import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  // Valores que la pantalla va a mostrar en tiempo real
  final ValueNotifier<int> pasos = ValueNotifier(0);
  final ValueNotifier<double> aceleracion = ValueNotifier(0);
  final ValueNotifier<String> intensidad = ValueNotifier('Descanso');
  final ValueNotifier<double> giroX = ValueNotifier(0);
  final ValueNotifier<double> giroY = ValueNotifier(0);
  final ValueNotifier<double> giroZ = ValueNotifier(0);
  final ValueNotifier<String?> error = ValueNotifier(null);

  StreamSubscription<StepCount>? _subPasos;
  StreamSubscription<UserAccelerometerEvent>? _subAcel;
  StreamSubscription<GyroscopeEvent>? _subGiro;

  int? _pasosBase;

  void iniciar() {
    detener(); // por si ya estaban activos
    _pasosBase = null;
    pasos.value = 0;
    error.value = null;

    // Podómetro: el sensor cuenta desde que se encendió el celular,
    // por eso guardamos el primer valor como base.
    try {
      _subPasos = Pedometer.stepCountStream.listen(
            (evento) {
          _pasosBase ??= evento.steps;
          pasos.value = evento.steps - _pasosBase!;
        },
        onError: (_) => error.value = 'Este dispositivo no tiene podómetro',
      );
    } catch (_) {
      error.value = 'No se pudo iniciar el podómetro';
    }

    // Acelerómetro (sin gravedad): mide la intensidad del movimiento
    try {
      _subAcel = userAccelerometerEventStream().listen(
            (e) {
          final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          aceleracion.value = mag;
          if (mag < 1.0) {
            intensidad.value = 'Descanso';
          } else if (mag < 4.0) {
            intensidad.value = 'Caminata';
          } else {
            intensidad.value = 'Trote';
          }
        },
        onError: (_) => error.value = 'Este dispositivo no tiene acelerómetro',
      );
    } catch (_) {
      error.value = 'No se pudo iniciar el acelerómetro';
    }

    // Giroscopio: velocidad angular (rad/s)
    try {
      _subGiro = gyroscopeEventStream().listen(
            (e) {
          giroX.value = e.x;
          giroY.value = e.y;
          giroZ.value = e.z;
        },
        onError: (_) => error.value = 'Este dispositivo no tiene giroscopio',
      );
    } catch (_) {
      error.value = 'No se pudo iniciar el giroscopio';
    }
  }

  // Libera los sensores para no gastar batería
  void detener() {
    _subPasos?.cancel();
    _subAcel?.cancel();
    _subGiro?.cancel();
    _subPasos = null;
    _subAcel = null;
    _subGiro = null;
  }

  // Reinicia los valores a cero al terminar entrenamiento
  void reset() {
    pasos.value = 0;
    aceleracion.value = 0;
    intensidad.value = 'Descanso';
    giroX.value = 0;
    giroY.value = 0;
    giroZ.value = 0;
    error.value = null;
    _pasosBase = null;
  }

  void dispose() {
    detener();
    pasos.dispose();
    aceleracion.dispose();
    intensidad.dispose();
    giroX.dispose();
    giroY.dispose();
    giroZ.dispose();
    error.dispose();
  }
}