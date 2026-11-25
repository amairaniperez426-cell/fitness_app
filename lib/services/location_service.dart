import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final ValueNotifier<List<LatLng>> ruta = ValueNotifier([]);
  final ValueNotifier<double> distanciaMetros = ValueNotifier(0);
  final ValueNotifier<double> velocidadKmh = ValueNotifier(0);
  final ValueNotifier<LatLng?> posicionActual = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  StreamSubscription<Position>? _sub;

  /// Obtiene la ubicación actual puntual del usuario para mostrarla en el mapa.
  Future<void> obtenerUbicacionActual() async {
    try {
      final gpsActivo = await Geolocator.isLocationServiceEnabled();
      if (!gpsActivo) {
        error.value = 'Activa el GPS del dispositivo';
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        error.value = 'Sin permiso de ubicación';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final punto = LatLng(pos.latitude, pos.longitude);
      posicionActual.value = punto;
      error.value = null;
    } catch (_) {
      error.value = 'No se pudo obtener la ubicación actual';
    }
  }

  /// Inicia la escucha continua del GPS y el registro de la ruta.
  Future<void> iniciar() async {
    detener();
    ruta.value = [];
    distanciaMetros.value = 0;
    velocidadKmh.value = 0;
    error.value = null;

    try {
      final gpsActivo = await Geolocator.isLocationServiceEnabled();
      if (!gpsActivo) {
        error.value = 'Activa el GPS del dispositivo';
        return;
      }

      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        error.value = 'Sin permiso de ubicación';
        return;
      }

      // Obtiene la posición inicial de inmediato
      try {
        final posInicial = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final puntoInicial = LatLng(posInicial.latitude, posInicial.longitude);
        posicionActual.value = puntoInicial;
        ruta.value = [puntoInicial];
      } catch (_) {}

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (pos) {
          final punto = LatLng(pos.latitude, pos.longitude);
          final lista = List<LatLng>.from(ruta.value);

          if (lista.isNotEmpty) {
            final anterior = lista.last;
            distanciaMetros.value += Geolocator.distanceBetween(
              anterior.latitude,
              anterior.longitude,
              punto.latitude,
              punto.longitude,
            );
          }

          lista.add(punto);
          ruta.value = lista;
          posicionActual.value = punto;
          velocidadKmh.value = pos.speed * 3.6; // m/s a km/h
        },
        onError: (_) => error.value = 'Error al leer el GPS',
      );
    } catch (_) {
      error.value = 'No se pudo iniciar el GPS';
    }
  }

  // Libera el GPS para no gastar batería
  void detener() {
    _sub?.cancel();
    _sub = null;
  }

  // Reinicia la ruta y métricas de ubicación al terminar entrenamiento
  void reset() {
    ruta.value = [];
    distanciaMetros.value = 0;
    velocidadKmh.value = 0;
    error.value = null;
  }

  void dispose() {
    detener();
    ruta.dispose();
    distanciaMetros.dispose();
    velocidadKmh.dispose();
    posicionActual.dispose();
    error.dispose();
  }
}