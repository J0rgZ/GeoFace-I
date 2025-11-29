// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Información del Dispositivo
// @Autor:        Sistema GeoFace
// @Descripción:  Servicio para obtener información del dispositivo y
//               registrarlo en SharedPreferences.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dispositivo_info.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _keyDeviceId = 'device_id';
  static const String _keyDeviceMarca = 'device_marca';
  static const String _keyDeviceModelo = 'device_modelo';
  static const String _keyDeviceSO = 'device_so';
  static const String _keyDeviceVersionSO = 'device_version_so';
  static const String _keyDeviceFechaRegistro = 'device_fecha_registro';

  /// Obtiene o genera el ID único del dispositivo
  Future<String> obtenerDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);

    if (deviceId == null || deviceId.isEmpty) {
      // Generar nuevo ID único
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 
                   'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Para otras plataformas, generar un ID único
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      await prefs.setString(_keyDeviceId, deviceId);
    }

    return deviceId;
  }

  /// Obtiene la información completa del dispositivo
  Future<DispositivoInfo> obtenerInformacionDispositivo() async {
    final prefs = await SharedPreferences.getInstance();
    
    String marca = 'Desconocida';
    String modelo = 'Desconocido';
    String? sistemaOperativo;
    String? versionSO;
    DateTime fechaRegistro = DateTime.now();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        marca = androidInfo.manufacturer;
        modelo = androidInfo.model;
        sistemaOperativo = 'Android';
        versionSO = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        marca = 'Apple';
        modelo = iosInfo.model;
        sistemaOperativo = 'iOS';
        versionSO = iosInfo.systemVersion;
      } else {
        // Para otras plataformas (Windows, macOS, Linux), usar valores genéricos
        marca = 'Desconocida';
        modelo = 'Desconocido';
        sistemaOperativo = Platform.operatingSystem;
        versionSO = Platform.operatingSystemVersion;
      }
    } catch (e) {
      print('Error al obtener información del dispositivo: $e');
    }

    // Verificar si ya está registrado
    final fechaRegistroStr = prefs.getString(_keyDeviceFechaRegistro);
    if (fechaRegistroStr != null) {
      fechaRegistro = DateTime.parse(fechaRegistroStr);
    } else {
      // Primera vez, guardar fecha de registro
      await prefs.setString(_keyDeviceFechaRegistro, fechaRegistro.toIso8601String());
      await prefs.setString(_keyDeviceMarca, marca);
      await prefs.setString(_keyDeviceModelo, modelo);
      if (sistemaOperativo != null) {
        await prefs.setString(_keyDeviceSO, sistemaOperativo);
      }
      if (versionSO != null) {
        await prefs.setString(_keyDeviceVersionSO, versionSO);
      }
    }

    final deviceId = await obtenerDeviceId();

    return DispositivoInfo(
      id: deviceId,
      marca: marca,
      modelo: modelo,
      sistemaOperativo: sistemaOperativo,
      versionSO: versionSO,
      fechaRegistro: fechaRegistro,
      fechaUltimaActualizacion: fechaRegistroStr != null ? DateTime.now() : null,
    );
  }

  /// Obtiene información del dispositivo desde SharedPreferences (más rápido)
  Future<DispositivoInfo?> obtenerInformacionDispositivoCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    final deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null) return null;

    final marca = prefs.getString(_keyDeviceMarca) ?? 'Desconocida';
    final modelo = prefs.getString(_keyDeviceModelo) ?? 'Desconocido';
    final sistemaOperativo = prefs.getString(_keyDeviceSO);
    final versionSO = prefs.getString(_keyDeviceVersionSO);
    final fechaRegistroStr = prefs.getString(_keyDeviceFechaRegistro);

    if (fechaRegistroStr == null) return null;

    return DispositivoInfo(
      id: deviceId,
      marca: marca,
      modelo: modelo,
      sistemaOperativo: sistemaOperativo,
      versionSO: versionSO,
      fechaRegistro: DateTime.parse(fechaRegistroStr),
      fechaUltimaActualizacion: null,
    );
  }
}

