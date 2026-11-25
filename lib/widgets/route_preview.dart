import 'dart:math';
import 'package:flutter/material.dart';

class RoutePoint {
  final double lat;
  final double lng;
  const RoutePoint(this.lat, this.lng);
}

/// Dibuja la ruta sin internet ni API key.
class RoutePreview extends StatelessWidget {
  final List<RoutePoint> points;
  final double strokeWidth;

  const RoutePreview({super.key, required this.points, this.strokeWidth = 4});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Icon(Icons.location_off, color: Colors.white24),
      );
    }
    return CustomPaint(
      painter: _RoutePainter(points, strokeWidth),
      size: Size.infinite,
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<RoutePoint> pts;
  final double stroke;
  _RoutePainter(this.pts, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final minLat = pts.map((p) => p.lat).reduce(min);
    final maxLat = pts.map((p) => p.lat).reduce(max);
    final minLng = pts.map((p) => p.lng).reduce(min);
    final maxLng = pts.map((p) => p.lng).reduce(max);

    final midLat = (minLat + maxLat) / 2;
    final kx = cos(midLat * pi / 180);
    final w = max((maxLng - minLng) * kx, 1e-9);
    final h = max(maxLat - minLat, 1e-9);

    const pad = 16.0;
    final scale = min((size.width - pad * 2) / w, (size.height - pad * 2) / h);
    final offX = (size.width - w * scale) / 2;
    final offY = (size.height - h * scale) / 2;

    Offset toOffset(RoutePoint p) => Offset(
      offX + (p.lng - minLng) * kx * scale,
      size.height - (offY + (p.lat - minLat) * scale),
    );

    final path = Path()
      ..moveTo(toOffset(pts.first).dx, toOffset(pts.first).dy);
    for (final p in pts.skip(1)) {
      final o = toOffset(p);
      path.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
        toOffset(pts.first), stroke + 2, Paint()..color = Colors.greenAccent);
    canvas.drawCircle(
        toOffset(pts.last), stroke + 2, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.pts != pts;
}