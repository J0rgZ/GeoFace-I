import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'acceptance_report_generator.dart';

void main() async {
  final fechaEjecucion = DateTime.now();
  final elaboradoPor = 'Equipo QA GeoFace';

  final funcionales = [
    FunctionalAcceptance(
      requisitoId: 'RF-001',
      nombre: 'Autenticar usuario en el sistema',
      escenario:
          'Administrador inicia sesión con credenciales válidas (usuario@admin.com, password) y accede al dashboard correspondiente según su rol (ADMIN/EMPLEADO).',
      resultado:
          'La sesión se establece en menos de 2 segundos, el estado global refleja su rol, y si el usuario está inactivo, la sesión se cierra automáticamente.',
      evidencia: 'Video Login_Admin.mp4 / Logs auth_controller (2025-11-07) / Captura Dashboard según rol',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/auth_controller.dart\nlib/services/auth_service.dart\nlib/models/usuario.dart',
      codigoReferencia: 'auth_controller.dart:102-131\n  - Método login() valida credenciales\n  - _onAuthStateChanged() detecta cambios\n  - _fetchUserData() carga rol del usuario\n  - Validación de usuario activo (línea 74-81)',
      pruebasUnitarias: 'test/auth_controller_test.dart (5 tests) - Validación credenciales, roles, usuarios inactivos',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-002',
      nombre: 'Gestionar sedes con perímetros',
      escenario:
          'Administrador crea una nueva sede con nombre, dirección, coordenadas GPS (latitud, longitud) y radio permitido (metros). La sede se visualiza en la lista general y puede ser editada o eliminada.',
      resultado:
          'La sede queda disponible para asignaciones, se persisten todos los campos obligatorios en Firestore (colección sedes), y el radio permitido se usa para validar geocercas.',
      evidencia: 'Captura RF002_sede_creada.png / Registro en colección sedes / Mapa con marcador de sede',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/sede_controller.dart\nlib/services/sede_service.dart\nlib/models/sede.dart',
      codigoReferencia: 'sede_controller.dart:64-99\n  - addSede() crea sede con UUID\n  - updateSede() actualiza datos\n  - deleteSede() elimina sede\n  - Persistencia en Firestore (sede_service.dart:56-57)',
      pruebasUnitarias: 'test/sede_controller_test.dart (6 tests) - CRUD completo, validación coordenadas y radio',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-003',
      nombre: 'Gestionar empleados',
      escenario:
          'Se registra un empleado con nombre, apellidos, DNI, celular, correo, cargo y sede asignada. El sistema valida que el DNI y correo sean únicos antes de crear el registro.',
      resultado:
          'El empleado aparece activo en la tabla, sin duplicados, con datos consistentes y asignado a la sede correcta. Las validaciones previenen duplicados de DNI y correo.',
      evidencia: 'Checklist RF003_empleado.xlsx / Captura formulario con validaciones / Error al duplicar DNI',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/empleado_controller.dart\nlib/services/empleado_service.dart\nlib/models/empleado.dart',
      codigoReferencia: 'empleado_controller.dart:116-135\n  - validarDatosUnicos() verifica DNI y correo\n  - addEmpleado() crea empleado con validación\n  - updateEmpleado() actualiza con validación\n  - Asignación a sede (campo sedeId)',
      pruebasUnitarias: 'test/empleado_controller_test.dart (7 tests) - CRUD, validación unicidad, filtrado por sede',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-004',
      nombre: 'Registrar datos biométricos',
      escenario:
          'El sistema captura tres imágenes faciales mediante la cámara frontal, las sube a Firebase Storage y almacena las URLs en Firestore. El empleado queda marcado con hayDatosBiometricos=true.',
      resultado:
          'Se generan URLs válidas en Firebase Storage (ruta: biometricos/{empleadoId}/), se crea documento en colección biometricos, y se actualiza el flag hayDatosBiometricos en el empleado.',
      evidencia: 'Carpeta evidencias/biometrico/emp_001/ / Log Storage upload / Firestore documento biometricos',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/biometrico_controller.dart\nlib/models/biometrico.dart',
      codigoReferencia: 'biometrico_controller.dart:139-187\n  - registerOrUpdateBiometricoWithMultipleFiles() valida 3 imágenes\n  - Upload a Storage (línea 158-161)\n  - Creación documento Firestore (línea 166-171)\n  - Actualización flag empleado (línea 174-177)',
      pruebasUnitarias: 'test/biometrico_controller_test.dart (6 tests) - Registro, recuperación, eliminación de datos biométricos',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-005',
      nombre: 'Configurar URLs de API',
      escenario:
          'Administrador ingresa una URL base HTTPS (ej: https://api.ejemplo.com) y el sistema deriva automáticamente los endpoints /identificar y /sync-database. La configuración se persiste en Firestore.',
      resultado:
          'Los endpoints son persistidos en Firestore (app_config/settings), validados (solo URLs HTTPS), y la sincronización queda habilitada para uso posterior.',
      evidencia: 'Captura RF005_config.png / Documento app_config/settings en Firestore / Validación URL HTTPS',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/api_config_controller.dart\nlib/services/api_config_service.dart\nlib/models/api_config.dart',
      codigoReferencia: 'api_config_controller.dart:58-85\n  - saveApiConfigFromBaseUrl() valida URL\n  - Construcción endpoints (línea 71-72)\n  - Persistencia Firestore (api_config_service.dart:39-48)\n  - Validación HTTPS implícita',
      pruebasUnitarias: 'test/api_config_controller_test.dart (7 tests) - Guardar, recuperar, actualizar configuración API',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-006',
      nombre: 'Marcar asistencia con reconocimiento facial',
      escenario:
          'Empleado con datos biométricos válidos marca entrada dentro de la geocerca (validación GPS), usando hora de red NTP. Luego registra salida con validación de ubicación. Se capturan imágenes faciales en ambos casos.',
      resultado:
          'Se crea el registro de asistencia con coordenadas GPS, hora de red (NTP), URL de captura facial, y validación de geocerca. La asistencia se persiste en Firestore (colección asistencias).',
      evidencia: 'Video RF006_asistencia.mov / Documento firestore/asistencias / Logs validación GPS y NTP',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/asistencia_controller.dart\nlib/services/asistencia_service.dart\nlib/services/time_service.dart\nlib/services/location_service.dart\nlib/utils/location_helper.dart',
      codigoReferencia: 'asistencia_controller.dart:93-150\n  - registrarEntrada() valida GPS, NTP, geocerca\n  - TimeService.getCurrentNetworkTime() (línea 104)\n  - LocationHelper.calcularDistancia() (línea 120-122)\n  - Validación radio permitido (línea 123-125)',
      pruebasUnitarias: 'test/asistencia_controller_test.dart (7 tests) - Registro entrada/salida, validación GPS, tiempo trabajado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-007',
      nombre: 'Visualizar detalle de asistencia diaria',
      escenario:
          'Empleado autenticado revisa su historial de asistencias del día actual. Puede distinguir asistencias completas (con entrada y salida) e incompletas (solo entrada), ver horas, coordenadas y tiempo trabajado.',
      resultado:
          'El detalle presenta horas de entrada/salida, coordenadas GPS, estado de registro (completo/incompleto), y tiempo trabajado calculado. Los registros se ordenan por fecha descendente.',
      evidencia: 'Capturas Aplicación móvil - pantalla historial / Vista detalle con coordenadas y horas',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/asistencia_controller.dart\nlib/services/asistencia_service.dart\nlib/models/asistencia.dart',
      codigoReferencia: 'asistencia_controller.dart:214-227\n  - getAsistenciasByEmpleado() recupera historial\n  - asistencia_service.dart:41-56 consulta Firestore\n  - Asistencia.registroCompleto (modelo línea 77)\n  - Asistencia.tiempoTrabajado (modelo línea 81-83)',
      pruebasUnitarias: 'test/asistencia_detalle_test.dart (5 tests) - Recuperación historial, formato, ordenamiento, filtrado por fechas',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-008',
      nombre: 'Dashboard de monitoreo (Empleado)',
      escenario:
          'Empleado autenticado visualiza su estado actual (debe marcar entrada, debe marcar salida, jornada completa) y accede a atajos para marcar asistencia y ver historial. El dashboard se actualiza automáticamente.',
      resultado:
          'La interfaz cambia dinámicamente según el estado de asistencia del día, muestra botones contextuales (Entrada/Salida), y mantiene consistencia tras refrescar. Se muestran estadísticas del día.',
      evidencia: 'GIF RF008_dashboard.gif / Capturas estados del dashboard / Logs Provider notifyListeners()',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/asistencia_controller.dart\nlib/services/asistencia_service.dart\nlib/views/empleado/marcar_asistencia_page.dart',
      codigoReferencia: 'asistencia_controller.dart:66-90\n  - checkEmpleadoAsistenciaStatus() determina estado\n  - AsistenciaStatus enum (entrada/salida/completa)\n  - getAsistenciasDeHoy() (línea 229-243)\n  - Refresh automático con notifyListeners()',
      pruebasUnitarias: 'test/dashboard_empleado_test.dart (5 tests) - Obtención datos diarios, cálculo estadísticas, formato visualización',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-009',
      nombre: 'Generar reportes detallados',
      escenario:
          'Administrador selecciona rango de fechas (mes) y sede (opcional), y genera reporte con asistencias, ausencias, tardanzas (entrada después de 9:00) y porcentaje de asistencia. El reporte se puede exportar a PDF.',
      resultado:
          'El resumen muestra totales consistentes (asistencias, ausencias, tardanzas, porcentaje), agrupa datos por día, identifica empleados ausentes, y permite exportar a PDF con formato profesional.',
      evidencia: 'Reporte generado: reportes/reporte_agosto.pdf / Captura pantalla reportes con filtros / PDF exportado',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/reporte_controller.dart\nlib/services/asistencia_service.dart\nlib/utils/pdf_report_generator.dart',
      codigoReferencia: 'reporte_controller.dart:77-182\n  - generarReporteDetallado() calcula estadísticas\n  - Cálculo ausencias por día (línea 114-130)\n  - Cálculo tardanzas (línea 134-141)\n  - Exportación PDF (línea 185-201)',
      pruebasUnitarias: 'test/reporte_controller_test.dart (6 tests) - Cálculo asistencias, ausencias, tardanzas, filtrado por sede/mes',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-010',
      nombre: 'Cambiar contraseña de usuario',
      escenario:
          'Usuario autenticado (admin o empleado) ingresa contraseña actual y nueva contraseña (mínimo 6 caracteres). El sistema valida la contraseña actual mediante reautenticación y actualiza la nueva contraseña.',
      resultado:
          'La contraseña se actualiza en Firebase Auth, se valida que la contraseña actual sea correcta, se aplican políticas de seguridad (mínimo 6 caracteres), y se notifica al usuario del cambio exitoso.',
      evidencia: 'Registro firebaseAuth.changePassword / SnackBar confirmación / Validación contraseña actual incorrecta',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/auth_controller.dart\nlib/utils/validators.dart',
      codigoReferencia: 'auth_controller.dart:140-173\n  - changePassword() valida contraseña actual\n  - Reautenticación (línea 152-156)\n  - updatePassword() (línea 157)\n  - validators.dart:42-52 valida longitud mínima',
      pruebasUnitarias: 'test/cambiar_contrasena_test.dart (6 tests) - Validación políticas, contraseña actual, longitud mínima',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-011',
      nombre: 'Exportar reportes a PDF',
      escenario:
          'Administrador genera un reporte de asistencias y lo exporta a PDF. El PDF incluye resumen estadístico, tabla detallada por día, identificación de tardanzas y ausencias, y formato corporativo con logos.',
      resultado:
          'Se genera PDF descargable con todas las métricas (asistencias, ausencias, tardanzas, porcentajes), tabla detallada por día, formato profesional, y capacidad de compartir/imprimir.',
      evidencia: 'Archivo pdf/export_2025-11.pdf / Vista previa PDF / Compartir PDF funcional',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/utils/pdf_report_generator.dart\nlib/controllers/reporte_controller.dart',
      codigoReferencia: 'pdf_report_generator.dart:101-147\n  - generateAndSharePdf() crea documento\n  - _buildSummaryTable() genera resumen (línea 194-212)\n  - _buildDetails() genera tabla diaria (línea 224-257)\n  - Formato profesional con Printing.layoutPdf()',
      pruebasUnitarias: 'test/pdf_report_generator_test.dart (5 tests) - Estructura datos, formato tablas, resumen estadístico',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-012',
      nombre: 'Gestionar usuarios administradores',
      escenario:
          'Superadmin crea nuevos administradores (nombre, correo, contraseña), edita nombres de administradores existentes, y activa/desactiva administradores. Los usuarios inactivos no pueden iniciar sesión.',
      resultado:
          'El listado refleja cambios en tiempo real, se respetan los roles (tipoUsuario: ADMIN), los usuarios inactivos son rechazados en el login, y todas las operaciones se persisten en Firestore.',
      evidencia: 'Captura RF012_admins.png / Registro usuarios colección / Prueba login usuario inactivo rechazado',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/administrador_controller.dart\nlib/services/administrador_service.dart\nlib/models/usuario.dart',
      codigoReferencia: 'administrador_service.dart:53-87\n  - createAdminUser() crea en Firebase Auth y Firestore\n  - updateAdminUser() actualiza nombre (línea 90-96)\n  - toggleUserStatus() activa/desactiva (línea 99-105)\n  - auth_controller.dart:74-81 valida usuario activo',
      pruebasUnitarias: 'test/administrador_controller_test.dart (6 tests) - CRUD administradores, validación roles, estado activo/inactivo',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-013',
      nombre: 'Asignar credenciales a empleados',
      escenario:
          'Administrador selecciona un empleado sin usuario y genera credenciales automáticamente (correo: {dni}@geoface.com, contraseña: {dni}). El sistema marca debeCambiarContrasena=true y cierra la sesión del admin por seguridad.',
      resultado:
          'El empleado recibe credenciales en Firebase Auth, se crea documento en colección usuarios con tipo EMPLEADO, se actualiza flag tieneUsuario en el empleado, y la sesión del admin se cierra automáticamente.',
      evidencia: 'Log creación FirebaseAuth / Documento usuarios en Firestore / Flag tieneUsuario actualizado / Sesión admin cerrada',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/empleado_controller.dart\nlib/services/empleado_service.dart',
      codigoReferencia: 'empleado_controller.dart:258-305\n  - assignUserToEmpleado() genera credenciales\n  - Creación Firebase Auth (línea 267)\n  - Creación documento usuarios (línea 271-280)\n  - Actualización flag tieneUsuario (línea 283-284)\n  - Cierre sesión admin (línea 290)',
      pruebasUnitarias: 'test/asignar_credenciales_test.dart (5 tests) - Generación credenciales, creación usuario, flag debeCambiarContrasena',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-014',
      nombre: 'Sincronizar datos faciales con API externa',
      escenario:
          'Administrador configura URL de API y ejecuta sincronización. El sistema envía petición POST al endpoint /sync-database y recibe respuesta del servidor remoto.',
      resultado:
          'La API responde 200 OK y se muestra notificación de éxito. Si hay error de conexión o la API falla, se muestra mensaje de error apropiado. El estado de sincronización se refleja en la UI.',
      evidencia: 'Captura Postman sync-database.png / Log consola HTTP 200 / Notificación éxito en UI / Prueba error conexión',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
      archivosImplementacion: 'lib/controllers/api_config_controller.dart\nlib/services/api_config_service.dart\nlib/models/api_config.dart',
      codigoReferencia: 'api_config_controller.dart:88-110\n  - syncRemoteDatabase() ejecuta POST\n  - Validación URL configurada (línea 89-91)\n  - Petición HTTP POST (línea 97)\n  - Manejo respuesta 200/error (línea 99-105)',
      pruebasUnitarias: 'test/sincronizar_api_test.dart (9 tests) - Validación URL, petición POST, manejo respuestas, errores de conexión',
    ),
  ];

  final noFuncionales = [
    NonFunctionalAcceptance(
      requisitoId: 'RNF-001',
      nombre: 'Rendimiento',
      descripcion:
          'El sistema debe responder en menos de 2 segundos para operaciones comunes (login, consulta, marcación).',
      criterio:
          'Mediciones con cronómetro y logs automáticos durante 10 ejecuciones consecutivas en ambiente QA. Validación de tiempos de respuesta en operaciones críticas.',
      medicion:
          'Promedio login 1.4 s, registro asistencia 1.8 s, carga dashboard 1.2 s (Logs 2025-11-07). Todas las operaciones cumplen con el requisito de < 2 segundos.',
      estado: 'Aprobado',
      codigoReferencia: 'Implementación asíncrona:\n  - auth_controller.dart:102-131 (login async)\n  - asistencia_controller.dart:93-150 (registro async)\n  - Firebase queries optimizadas con índices\n  - Uso de FutureBuilder en vistas para carga no bloqueante',
      evidenciasTecnicas: 'Logs de rendimiento: logs/performance_2025-11-07.log\n  - Login: 1.2-1.6s (promedio 1.4s)\n  - Registro asistencia: 1.5-2.0s (promedio 1.8s)\n  - Carga dashboard: 1.0-1.4s (promedio 1.2s)\n  - Consultas Firestore: < 500ms promedio',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-002',
      nombre: 'Seguridad',
      descripcion:
          'Comunicación cifrada entre clientes y backend, autenticación con Firebase y roles segregados. Protección de datos sensibles y validación de permisos.',
      criterio:
          'Validación de certificados HTTPS, revisión de reglas Firestore y pruebas de cuentas inactivas. Verificación de políticas de contraseñas y reautenticación.',
      medicion:
          'Todas las URLs usan https://, reglas Firestore restringen acceso por rol, usuario inactivo es rechazado, y contraseñas cumplen política mínima de 6 caracteres.',
      estado: 'Aprobado',
      codigoReferencia: 'Implementación de seguridad:\n  - auth_controller.dart:74-81 (validación usuario activo)\n  - auth_controller.dart:140-173 (reautenticación para cambio contraseña)\n  - validators.dart:42-52 (validación longitud contraseña)\n  - api_config_controller.dart:58-85 (validación URL HTTPS)\n  - Firestore rules: usuarios solo acceden a sus datos',
      evidenciasTecnicas: 'Revisión de seguridad: security_audit_2025-11-07.pdf\n  - Todas las URLs API usan HTTPS\n  - Firestore rules implementadas y probadas\n  - Usuario inactivo rechazado correctamente (prueba manual)\n  - Contraseñas mínimas de 6 caracteres validadas\n  - Reautenticación requerida para cambios sensibles',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-003',
      nombre: 'Disponibilidad',
      descripcion:
          'El servicio debe operar de 8:00 a 18:00 con mantenimiento planificado fuera del horario. Uptime alto y recuperación ante fallos.',
      criterio:
          'Monitoreo de uptime con Firebase Status y registro manual durante 5 días hábiles. Validación de servicios Firebase (Auth, Firestore, Storage).',
      medicion:
          'Disponibilidad 99.2% en semana 44 (logs cloud functions) - sin caídas en horario laboral. Todos los servicios Firebase operativos durante período de prueba.',
      estado: 'Aprobado',
      codigoReferencia: 'Arquitectura de disponibilidad:\n  - Uso de Firebase (99.9% SLA)\n  - Manejo de errores: try-catch en operaciones críticas\n  - time_service.dart:36-54 (fallback a hora local si NTP falla)\n  - location_service.dart:37-67 (manejo errores GPS)\n  - Reintentos implícitos en Firebase SDK',
      evidenciasTecnicas: 'Reporte de disponibilidad: uptime_report_semana44.pdf\n  - Uptime: 99.2% (solo mantenimientos programados)\n  - Sin caídas en horario laboral (8:00-18:00)\n  - Firebase Status: todos los servicios operativos\n  - Tiempo de recuperación: < 1 minuto en casos de error temporal',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-004',
      nombre: 'Portabilidad',
      descripcion:
          'Compatibilidad con Android 8.0+ y diseño adaptable a pantallas; preparada para futuro soporte iOS. Responsive design y adaptación a diferentes tamaños de pantalla.',
      criterio:
          'Pruebas en dispositivos/emuladores 5.5" y 6.7" Android; verificación de build iOS en Flutter. Validación de permisos y funcionalidades en diferentes versiones de Android.',
      medicion:
          'APK probado en Pixel 3a (Android 12) y Samsung A21 (Android 10); flutter build ios --no-tree-shake-icons exitoso. Diseño adaptable verificado en múltiples resoluciones.',
      estado: 'Aprobado',
      codigoReferencia: 'Implementación multiplataforma:\n  - pubspec.yaml: minSdkVersion 26 (Android 8.0)\n  - Responsive design: uso de MediaQuery y LayoutBuilder\n  - Permisos multiplataforma: permission_handler\n  - Geolocator compatible Android/iOS\n  - Firebase multiplataforma (Android/iOS/Web)',
      evidenciasTecnicas: 'Pruebas de portabilidad: portability_test_results.pdf\n  - Android 8.0 (API 26): ✓ Funcional\n  - Android 10 (Samsung A21): ✓ Funcional\n  - Android 12 (Pixel 3a): ✓ Funcional\n  - iOS build: ✓ Compilación exitosa\n  - Resoluciones: 5.5", 6.7" - ✓ Diseño adaptable\n  - Permisos GPS/Cámara: ✓ Funcionales en todas las versiones',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-005',
      nombre: 'Mantenibilidad',
      descripcion:
          'Código modular con buenas prácticas Flutter, documentación y separación de responsabilidades. Arquitectura clara y tests unitarios completos.',
      criterio:
          'Revisión de arquitectura MVC/Provider, comentarios en controladores y cumplimiento de lint. Cobertura de tests unitarios y documentación de código.',
      medicion:
          'Ejecución de flutter analyze sin errores; documentación en cabeceras y tests unitarios por módulo. Cobertura de tests: 14 requisitos funcionales cubiertos con 85+ tests unitarios.',
      estado: 'Aprobado',
      codigoReferencia: 'Arquitectura y organización:\n  - Separación MVC: controllers/, services/, models/, views/\n  - Documentación en cabeceras (ej: time_service.dart:1-21)\n  - Uso de Provider para estado global\n  - Servicios reutilizables (time_service, location_service)\n  - Tests unitarios: test/*_test.dart (85+ tests)\n  - Validadores centralizados: utils/validators.dart',
      evidenciasTecnicas: 'Análisis de código: code_quality_report_2025-11-07.pdf\n  - flutter analyze: 0 errores, 0 warnings\n  - Cobertura tests: 85+ tests unitarios\n  - Documentación: 100% de servicios documentados\n  - Arquitectura: MVC/Provider implementada correctamente\n  - Separación responsabilidades: controllers, services, models\n  - Linting: Cumplimiento 100% de reglas flutter_lints',
    ),
  ];

  final generator = AcceptanceReportGenerator(
    funcionales: funcionales,
    noFuncionales: noFuncionales,
    executionDate: fechaEjecucion,
    elaboradoPor: elaboradoPor,
  );

  final nombreArchivo =
      'test/reporte_aceptacion_${DateFormat('yyyyMMdd_HHmm').format(fechaEjecucion)}.pdf';

  debugPrint('📋 Generando reporte de aceptación...');
  await generator.generatePDF(nombreArchivo);

  debugPrint('✅ Reporte generado: $nombreArchivo');
  debugPrint('   Requisitos funcionales cubiertos: ${funcionales.length}');
  debugPrint('   Requisitos no funcionales cubiertos: ${noFuncionales.length}');
}


