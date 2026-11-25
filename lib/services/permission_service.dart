import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Muestra un diálogo explicativo y luego pide el permiso
  static Future<bool> _pedir(
      BuildContext context,
      Permission permiso,
      String titulo,
      String mensaje,
      ) async {
    if (await permiso.isGranted) return true;
    if (!context.mounted) return false;

    final aceptar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (aceptar != true) return false;

    final estado = await permiso.request();
    if (estado.isPermanentlyDenied) {
      await openAppSettings(); // lo manda a Ajustes si lo negó para siempre
    }
    return estado.isGranted;
  }

  static Future<bool> pedirActividadFisica(BuildContext context) {
    return _pedir(
      context,
      Permission.activityRecognition,
      'Actividad física',
      'Necesitamos este permiso para contar tus pasos durante el entrenamiento.',
    );
  }

  static Future<bool> pedirUbicacion(BuildContext context) {
    return _pedir(
      context,
      Permission.locationWhenInUse,
      'Ubicación',
      'Necesitamos tu ubicación para trazar tu recorrido en el mapa.',
    );
  }
}