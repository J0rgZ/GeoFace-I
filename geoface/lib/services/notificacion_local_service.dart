// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Notificaciones Locales
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `NotificacionLocalService`, que maneja
//               las notificaciones locales del dispositivo. Solicita permisos y muestra
//               notificaciones cuando ocurren eventos relacionados con la asistencia.
//
// @NombreArchivo: notificacion_local_service.dart
// @Ubicacion:    lib/services/notificacion_local_service.dart
// @FechaInicio:  25/06/2025
// @FechaFin:     25/06/2025
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para manejar notificaciones locales en el dispositivo
class NotificacionLocalService {
  static final NotificacionLocalService _instance = NotificacionLocalService._internal();
  factory NotificacionLocalService() => _instance;
  NotificacionLocalService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;
  bool _permisosConcedidos = false;

  /// Inicializa el servicio de notificaciones locales
  Future<bool> inicializar() async {
    if (_inicializado) return _permisosConcedidos;

    try {
      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final inicializado = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (inicializado != null && inicializado) {
        _inicializado = true;
        // Crear el canal de notificaciones para Android (obligatorio desde Android 8.0+)
        await _crearCanalNotificaciones();
        _permisosConcedidos = await _solicitarPermisos();
        return _permisosConcedidos;
      }

      return false;
    } catch (e) {
      debugPrint('Error al inicializar notificaciones locales: $e');
      return false;
    }
  }

  /// Crea el canal de notificaciones para Android (obligatorio desde Android 8.0+)
  Future<void> _crearCanalNotificaciones() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const androidChannel = AndroidNotificationChannel(
        'geoface_notificaciones', // id del canal
        'Notificaciones GeoFace', // nombre del canal
        description: 'Notificaciones sobre asistencia de empleados',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Solicita permisos para mostrar notificaciones
  Future<bool> _solicitarPermisos() async {
    try {
      // En Android 13+ se necesita el permiso de notificaciones
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      
      // En iOS los permisos se solicitan automáticamente con la inicialización
      return true;
    } catch (e) {
      debugPrint('Error al solicitar permisos de notificaciones: $e');
      return false;
    }
  }

  /// Verifica si se tienen permisos para mostrar notificaciones
  Future<bool> verificarPermisos() async {
    if (!_inicializado) {
      await inicializar();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      _permisosConcedidos = status.isGranted;
      return _permisosConcedidos;
    }

    return _permisosConcedidos;
  }

  /// Solicita permisos al usuario
  Future<bool> solicitarPermisos() async {
    if (!_inicializado) {
      await inicializar();
    }

    _permisosConcedidos = await _solicitarPermisos();
    return _permisosConcedidos;
  }

  /// Muestra una notificación local
  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    if (!_inicializado) {
      final inicializado = await inicializar();
      if (!inicializado) {
        debugPrint('No se pueden mostrar notificaciones: servicio no inicializado');
        return;
      }
    }

    // Verificar permisos antes de mostrar
    final tienePermisos = await verificarPermisos();
    if (!tienePermisos) {
      debugPrint('No se tienen permisos para mostrar notificaciones');
      return;
    }

    try {
      // Configuración para Android
      const androidDetails = AndroidNotificationDetails(
        'geoface_notificaciones', // Debe coincidir con el ID del canal
        'Notificaciones GeoFace',
        channelDescription: 'Notificaciones sobre asistencia de empleados',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // Configuración para iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        titulo,
        cuerpo,
        notificationDetails,
        payload: payload,
      );
      
      debugPrint('✅ Notificación mostrada: $titulo');
    } catch (e) {
      debugPrint('❌ Error al mostrar notificación: $e');
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    // Aquí se puede manejar la navegación cuando se toca una notificación
  }

  /// Cancela todas las notificaciones
  Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
  }

  /// Cancela una notificación específica
  Future<void> cancelar(int id) async {
    await _notifications.cancel(id);
  }
}

