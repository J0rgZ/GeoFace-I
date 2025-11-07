# Pruebas Unitarias - GeoFace

Este directorio contiene las pruebas unitarias automatizadas para los 14 requisitos funcionales del sistema GeoFace.

## Requisitos Cubiertos

- **RF-001**: Autenticación de usuario
- **RF-002**: Gestión de Sedes con Perímetros
- **RF-003**: Gestión de Empleados
- **RF-004**: Registro de Datos Faciales
- **RF-005**: Configurar URLs de API
- **RF-006**: Marcar Asistencia con Reconocimiento Facial
- **RF-007**: Visualizar detalle de asistencia diaria (Empleado)
- **RF-008**: Visualizar dashboard de monitoreo (Empleado)
- **RF-009**: Generar reportes detallados de asistencia (Administrador)
- **RF-010**: Cambiar contraseña de usuario
- **RF-011**: Exportar reportes a formato PDF
- **RF-012**: Gestionar usuarios Administradores
- **RF-013**: Asignar credenciales de acceso a empleados
- **RF-014**: Sincronizar datos Faciales con API

## Instalación de Dependencias

Antes de ejecutar las pruebas, asegúrate de instalar las dependencias:

```bash
cd geoface
flutter pub get
```

## Ejecutar las Pruebas

### Ejecutar todas las pruebas:
```bash
flutter test
```

### Ejecutar una prueba específica:
```bash
flutter test test/auth_controller_test.dart
```

### Ejecutar pruebas con cobertura:
```bash
flutter test --coverage
```

## Generar Reporte PDF Automático

### Método Rápido (Recomendado):

**Windows:**
```bash
# Desde la raíz del proyecto geoface/
generate_test_report.bat
```

**Linux/Mac:**
```bash
# Desde la raíz del proyecto geoface/
chmod +x generate_test_report.sh
./generate_test_report.sh
```

Este comando:
1. ✅ Ejecuta todas las pruebas unitarias
2. ✅ Genera automáticamente un reporte PDF con los resultados
3. ✅ Guarda la salida de los tests en `test_output.txt`

El reporte PDF se guarda en: `test/reporte_pruebas_unitarias_YYYY-MM-DD.pdf`

### Método Manual:

```bash
# 1. Ejecutar las pruebas
flutter test

# 2. Generar el reporte PDF
dart run test/generate_test_report.dart
```

Para más detalles, consulta: `test/INSTRUCCIONES_REPORTE.md`

## Estructura de Archivos

- `auth_controller_test.dart` - Pruebas de autenticación (RF-001)
- `sede_controller_test.dart` - Pruebas de gestión de sedes (RF-002)
- `empleado_controller_test.dart` - Pruebas de gestión de empleados (RF-003)
- `biometrico_controller_test.dart` - Pruebas de registro biométrico (RF-004)
- `api_config_controller_test.dart` - Pruebas de configuración de API (RF-005)
- `asistencia_controller_test.dart` - Pruebas de marcado de asistencia (RF-006)
- `asistencia_detalle_test.dart` - Pruebas de detalle de asistencia (RF-007)
- `dashboard_empleado_test.dart` - Pruebas de dashboard empleado (RF-008)
- `reporte_controller_test.dart` - Pruebas de generación de reportes (RF-009)
- `cambiar_contrasena_test.dart` - Pruebas de cambio de contraseña (RF-010)
- `pdf_report_generator_test.dart` - Pruebas de exportación PDF (RF-011)
- `administrador_controller_test.dart` - Pruebas de gestión de administradores (RF-012)
- `asignar_credenciales_test.dart` - Pruebas de asignación de credenciales (RF-013)
- `sincronizar_api_test.dart` - Pruebas de sincronización con API (RF-014)

## Dependencias de Testing

- `flutter_test` - Framework de testing de Flutter
- `mockito` - Para crear mocks de dependencias
- `fake_cloud_firestore` - Para simular Firestore en pruebas
- `firebase_auth_mocks` - Para simular Firebase Auth en pruebas

