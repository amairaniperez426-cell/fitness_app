import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/entrenamiento.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/sensor_service.dart';
import '../widgets/pro_widgets.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _sensores = SensorService();
  final _ubicacion = LocationService();
  final _mapa = MapController();
  final ValueNotifier<int> _segundos = ValueNotifier(0);

  Timer? _timer;
  bool _entrenando = false;
  DateTime? _inicio;

  @override
  void initState() {
    super.initState();
    _ubicacion.posicionActual.addListener(_centrarMapa);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _obtenerUbicacionInicial();
    });
  }

  Future<void> _obtenerUbicacionInicial() async {
    final concedido = await PermissionService.pedirUbicacion(context);
    if (concedido) {
      await _ubicacion.obtenerUbicacionActual();
    }
  }

  void _centrarMapa() {
    final p = _ubicacion.posicionActual.value;
    if (p == null) return;
    try {
      _mapa.move(p, 17);
    } catch (_) {}
  }

  Future<void> _iniciar() async {
    // 1. Permisos con diálogo explicativo antes de activar los sensores
    await PermissionService.pedirActividadFisica(context);
    if (!mounted) return;
    await PermissionService.pedirUbicacion(context);
    if (!mounted) return;

    // 2. Arrancar sensores, GPS y cronómetro
    _segundos.value = 0;
    _inicio = DateTime.now();
    _sensores.iniciar();
    await _ubicacion.iniciar();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _segundos.value++;
    });
    setState(() => _entrenando = true);
  }

  Future<void> _detener() async {
    _timer?.cancel();
    _sensores.detener();
    _ubicacion.detener();

    if (_segundos.value > 0) {
      final entrenamiento = Entrenamiento(
        fecha: _inicio ?? DateTime.now(),
        duracionSegundos: _segundos.value,
        pasos: _sensores.pasos.value,
        distanciaMetros: _ubicacion.distanciaMetros.value,
        ruta: _ubicacion.ruta.value,
      );
      await DbService.instancia.guardar(entrenamiento);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entrenamiento guardado')));
      }
    }
    if (mounted) setState(() => _entrenando = false);
  }

  String _formatoTiempo(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final seg = (s % 60).toString().padLeft(2, '0');
    return '$m:$seg';
  }

  @override
  void dispose() {
    _ubicacion.posicionActual.removeListener(_centrarMapa);
    _timer?.cancel();
    _sensores.dispose();
    _ubicacion.dispose();
    _segundos.dispose();
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fitness App'),
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        imagePath: 'assets/images/gym.jpg',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
            child: Column(
              children: [
                // ---------- MAPA ----------
                SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapa,
                          options: MapOptions(
                            initialCenter:
                                _ubicacion.posicionActual.value ??
                                const LatLng(19.4326, -99.1332),
                            initialZoom: 17,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.fitness_app',
                            ),
                            ValueListenableBuilder<List<LatLng>>(
                              valueListenable: _ubicacion.ruta,
                              builder: (_, ruta, __) {
                                if (ruta.length < 2)
                                  return const SizedBox.shrink();
                                return PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: ruta,
                                      strokeWidth: 5,
                                      color: Colors.teal,
                                    ),
                                  ],
                                );
                              },
                            ),
                            ValueListenableBuilder<LatLng?>(
                              valueListenable: _ubicacion.posicionActual,
                              builder: (_, p, __) => MarkerLayer(
                                markers: [
                                  if (p != null)
                                    Marker(
                                      point: p,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: FloatingActionButton.small(
                            heroTag: 'btnUbicacion',
                            onPressed: () async {
                              if (_ubicacion.posicionActual.value == null) {
                                await _obtenerUbicacionInicial();
                              } else {
                                _centrarMapa();
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
        
                // ---------- AVISOS DE ERROR (sensor faltante, GPS apagado) ----------
                _Aviso(notifier: _sensores.error),
                _Aviso(notifier: _ubicacion.error),
        
                // ---------- MÉTRICAS ----------
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _segundos,
                      builder: (_, s, __) => _Tarjeta(
                        icono: Icons.timer,
                        titulo: 'Tiempo',
                        valor: _formatoTiempo(s),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: _sensores.pasos,
                      builder: (_, v, __) => _Tarjeta(
                        icono: Icons.directions_walk,
                        titulo: 'Pasos',
                        valor: '$v',
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: _ubicacion.distanciaMetros,
                      builder: (_, v, __) => _Tarjeta(
                        icono: Icons.route,
                        titulo: 'Distancia',
                        valor: '${(v / 1000).toStringAsFixed(2)} km',
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: _ubicacion.velocidadKmh,
                      builder: (_, v, __) => _Tarjeta(
                        icono: Icons.speed,
                        titulo: 'Velocidad',
                        valor: '${v.toStringAsFixed(1)} km/h',
                      ),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _sensores.intensidad,
                      builder: (_, v, __) => _Tarjeta(
                        icono: Icons.bolt,
                        titulo: 'Intensidad',
                        valor: v,
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: _sensores.aceleracion,
                      builder: (_, v, __) => _Tarjeta(
                        icono: Icons.vibration,
                        titulo: 'Aceleración',
                        valor: '${v.toStringAsFixed(2)} m/s²',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
        
                // ---------- GIROSCOPIO ----------
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _sensores.giroX,
                    _sensores.giroY,
                    _sensores.giroZ,
                  ]),
                  builder: (_, __) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.screen_rotation),
                      title: const Text('Giroscopio (rad/s)'),
                      subtitle: Text(
                        'X: ${_sensores.giroX.value.toStringAsFixed(2)}   '
                        'Y: ${_sensores.giroY.value.toStringAsFixed(2)}   '
                        'Z: ${_sensores.giroZ.value.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  text: 'VER HISTORIAL',
                  icon: Icons.history,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: 20),
        
                // ---------- BOTÓN INICIAR / DETENER ----------
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _entrenando ? Colors.red : null,
                    ),
                    onPressed: _entrenando ? _detener : _iniciar,
                    icon: Icon(_entrenando ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _entrenando ? 'Detener y guardar' : 'Iniciar entrenamiento',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _Tarjeta({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    return SizedBox(
      width: ancho,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(titulo, style: Theme.of(context).textTheme.labelMedium),
              Text(valor, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final ValueNotifier<String?> notifier;

  const _Aviso({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (_, msg, __) {
        if (msg == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.black87)),
        );
      },
    );
  }
}
