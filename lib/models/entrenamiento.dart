import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Entrenamiento {
  final int? id;
  final DateTime fecha;
  final int duracionSegundos;
  final int pasos;
  final double distanciaMetros;
  final List<LatLng> ruta;

  Entrenamiento({
    this.id,
    required this.fecha,
    required this.duracionSegundos,
    required this.pasos,
    required this.distanciaMetros,
    required this.ruta,
  });

  // Convierte el objeto a un mapa para guardarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'duracion': duracionSegundos,
      'pasos': pasos,
      'distancia': distanciaMetros,
      // la ruta se guarda como texto JSON: [[lat,lng],[lat,lng],...]
      'ruta': jsonEncode(ruta.map((p) => [p.latitude, p.longitude]).toList()),
    };
  }

  // Convierte una fila de SQLite de vuelta a objeto
  factory Entrenamiento.fromMap(Map<String, dynamic> map) {
    final lista = jsonDecode(map['ruta'] as String) as List;
    return Entrenamiento(
      id: map['id'] as int?,
      fecha: DateTime.parse(map['fecha'] as String),
      duracionSegundos: map['duracion'] as int,
      pasos: map['pasos'] as int,
      distanciaMetros: (map['distancia'] as num).toDouble(),
      ruta: lista
          .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList(),
    );
  }
}