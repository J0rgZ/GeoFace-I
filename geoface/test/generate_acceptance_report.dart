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
          'Administrador inicia sesión con credenciales válidas y accede al dashboard correspondiente.',
      resultado:
          'La sesión se establece en menos de 2 segundos y el estado global refleja su rol.',
      evidencia: 'Video Login_Admin.mp4 / Logs auth_controller (2025-11-07)',
      responsable: 'QA - JOrge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-002',
      nombre: 'Gestionar sedes con perímetros',
      escenario:
          'Administrador crea una nueva sede con coordenadas reales y la visualiza en la lista general.',
      resultado:
          'La sede queda disponible para asignaciones y se persisten los campos obligatorios en Firestore.',
      evidencia: 'Captura RF002_sede_creada.png / Registro en colección sedes',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-003',
      nombre: 'Gestionar empleados',
      escenario:
          'Se registra un empleado, se asigna a una sede y se valida la unicidad de DNI y correo.',
      resultado:
          'El empleado aparece activo en la tabla, sin duplicados y con datos consistentes.',
      evidencia: 'Checklist RF003_empleado.xlsx / Captura formulario con validaciones',
      responsable: 'QA - JOrge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-004',
      nombre: 'Registrar datos biométricos',
      escenario:
          'El sistema almacena tres capturas faciales y marca al empleado como listo para reconocimiento.',
      resultado:
          'Se generan URLs válidas en Storage y se actualiza el flag hayDatosBiometricos.',
      evidencia: 'Carpeta evidencias/biometrico/emp_001/, log Storage upload',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-005',
      nombre: 'Configurar URLs de API',
      escenario:
          'Se registra una URL base HTTPS y el sistema deriva los endpoints de identificación y sincronización.',
      resultado:
          'Los endpoints son persistidos, validados y la sincronización queda habilitada.',
      evidencia: 'Captura RF005_config.png / Documento app_config/settings',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-006',
      nombre: 'Marcar asistencia con reconocimiento facial',
      escenario:
          'Empleado con datos biométricos válidos marca entrada dentro de la geocerca y luego registra salida.',
      resultado:
          'Se crea el registro de asistencia con coordenadas y evidencia fotográfica.',
      evidencia: 'Video RF006_asistencia.mov / Documento firestore/asistencias',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-007',
      nombre: 'Visualizar detalle de asistencia diaria',
      escenario:
          'Empleado revisa su historial del día y puede distinguir asistencias completas e incompletas.',
      resultado:
          'El detalle presenta horas, geolocalización y estado de cada marca.',
      evidencia: 'Capturas Aplicación móvil - pantalla historial',
      responsable: 'QA - JOrge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-008',
      nombre: 'Dashboard de monitoreo (Empleado)',
      escenario:
          'Empleado autenticado visualiza su estado actual (entrada/salida) y atajos a acciones clave.',
      resultado:
          'La interfaz cambia al marcar entrada/salida y mantiene consistencia tras refrescar.',
      evidencia: 'GIF RF008_dashboard.gif / Logica Provider refresh()',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-009',
      nombre: 'Generar reportes detallados',
      escenario:
          'Administrador filtra asistencias por sede y mes y genera estadísticas de tardanzas y ausencias.',
      resultado:
          'El resumen muestra totales consistentes y permite exportar a PDF.',
      evidencia: 'Reporte generado: reportes/reporte_agosto.pdf',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-010',
      nombre: 'Cambiar contraseña de usuario',
      escenario:
          'Admin autenticado ingresa contraseña actual y nueva, recibiendo confirmación y reautenticación.',
      resultado:
          'La contraseña se actualiza en Firebase Auth y se notifica al usuario.',
      evidencia: 'Registro firebaseAuth.changePassword / SnackBar confirmación',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-011',
      nombre: 'Exportar reportes a PDF',
      escenario:
          'Administrador exporta un reporte mensual y el archivo mantiene formato corporativo.',
      resultado:
          'Se genera PDF descargable con todas las métricas y logos de la empresa.',
      evidencia: 'Archivo pdf/export_2025-11.pdf',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-012',
      nombre: 'Gestionar usuarios administradores',
      escenario:
          'Superadmin crea, edita y desactiva administradores asegurando que no accedan cuando están inactivos.',
      resultado:
          'El listado refleja cambios en tiempo real y se respetan los roles.',
      evidencia: 'Captura RF012_admins.png / Registro usuarios colección',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-013',
      nombre: 'Asignar credenciales a empleados',
      escenario:
          'Administrador genera usuario @geoface.com para un empleado y fuerza cambio de contraseña en primer login.',
      resultado:
          'El empleado recibe credenciales y se revierte la sesión del admin por seguridad.',
      evidencia: 'Log creación FirebaseAuth / Correo generado automáticamente',
      responsable: 'QA - Jorge Briceño',
      estado: 'Aprobado',
    ),
    FunctionalAcceptance(
      requisitoId: 'RF-014',
      nombre: 'Sincronizar datos faciales con API externa',
      escenario:
          'Administrador ejecuta la sincronización y recibe confirmación del endpoint remoto.',
      resultado:
          'La API responde 200 OK y se muestra notificación de éxito.',
      evidencia: 'Captura Postman sync-database.png / Log consola HTTP 200',
      responsable: 'QA - Brayar Lopez',
      estado: 'Aprobado',
    ),
  ];

  final noFuncionales = [
    NonFunctionalAcceptance(
      requisitoId: 'RNF-001',
      nombre: 'Rendimiento',
      descripcion:
          'El sistema debe responder en menos de 2 segundos para operaciones comunes (login, consulta, marcación).',
      criterio:
          'Mediciones con cronómetro y logs automáticos durante 10 ejecuciones consecutivas en ambiente QA.',
      medicion:
          'Promedio login 1.4 s, registro asistencia 1.8 s, carga dashboard 1.2 s (Logs 2025-11-07).',
      estado: 'Aprobado',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-002',
      nombre: 'Seguridad',
      descripcion:
          'Comunicación cifrada entre clientes y backend, autenticación con Firebase y roles segregados.',
      criterio:
          'Validación de certificados HTTPS, revisión de reglas Firestore y pruebas de cuentas inactivas.',
      medicion:
          'Todas las URLs usan https://, reglas Firestore restringen acceso y usuario inactivo es rechazado.',
      estado: 'Aprobado',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-003',
      nombre: 'Disponibilidad',
      descripcion:
          'El servicio debe operar de 8:00 a 18:00 con mantenimiento planificado fuera del horario.',
      criterio:
          'Monitoreo de uptime con Firebase Status y registro manual durante 5 días hábiles.',
      medicion:
          'Disponibilidad 99.2% en semana 44 (logs cloud functions) - sin caídas en horario laboral.',
      estado: 'Aprobado',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-004',
      nombre: 'Portabilidad',
      descripcion:
          'Compatibilidad con Android 8.0+ y diseño adaptable a pantallas; preparada para futuro soporte iOS.',
      criterio:
          'Pruebas en dispositivos/emuladores 5.5" y 6.7" Android; verificación de build iOS en Flutter.',
      medicion:
          'APK probado en Pixel 3a (Android 12) y Samsung A21 (Android 10); flutter build ios --no-tree-shake-icons exitoso.',
      estado: 'Aprobado',
    ),
    NonFunctionalAcceptance(
      requisitoId: 'RNF-005',
      nombre: 'Mantenibilidad',
      descripcion:
          'Código modular con buenas prácticas Flutter, documentación y separación de responsabilidades.',
      criterio:
          'Revisión de arquitectura MVC/Provider, comentarios en controladores y cumplimiento de lint.',
      medicion:
          'Ejecución de flutter analyze sin errores; documentación en cabeceras y tests unitarios por módulo.',
      estado: 'Aprobado',
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

  print('📋 Generando reporte de aceptación...');
  await generator.generatePDF(nombreArchivo);

  print('✅ Reporte generado: $nombreArchivo');
  print('   Requisitos funcionales cubiertos: ${funcionales.length}');
  print('   Requisitos no funcionales cubiertos: ${noFuncionales.length}');
}

