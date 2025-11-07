# 📊 Generador de Reporte PDF de Pruebas Unitarias

## Descripción
Sistema automatizado para generar reportes PDF profesionales con los resultados de todas las pruebas unitarias del sistema GeoFace.

## 🚀 Uso Rápido

### Windows
```bash
generate_test_report.bat
```

### Linux/Mac
```bash
chmod +x generate_test_report.sh
./generate_test_report.sh
```

## ✨ Características

- ✅ Ejecuta automáticamente todas las pruebas unitarias
- ✅ Genera reporte PDF profesional con formato corporativo
- ✅ Incluye resumen ejecutivo con estadísticas
- ✅ Detalle completo de pruebas por requisito funcional
- ✅ Tabla resumen de todos los requisitos
- ✅ Lista de todas las pruebas individuales ejecutadas

## 📋 Requisitos

- Flutter SDK instalado
- Dart SDK instalado
- Dependencias del proyecto instaladas (`flutter pub get`)

## 📄 Contenido del Reporte

El reporte PDF incluye:

1. **Encabezado**
   - Título del reporte
   - Nombre del sistema
   - Fecha y hora de ejecución

2. **Resumen Ejecutivo**
   - Total de pruebas: 85
   - Pruebas exitosas: 85
   - Pruebas fallidas: 0
   - Tasa de éxito: 100%

3. **Detalle por Requisito Funcional (14 requisitos)**
   - RF-001: Autenticación de Usuario (5 tests)
   - RF-002: Gestión de Sedes con Perímetros (6 tests)
   - RF-003: Gestión de Empleados (7 tests)
   - RF-004: Registro de Datos Faciales (6 tests)
   - RF-005: Configurar URLs de API (7 tests)
   - RF-006: Marcar Asistencia con Reconocimiento Facial (7 tests)
   - RF-007: Visualizar detalle de asistencia diaria (5 tests)
   - RF-008: Visualizar dashboard de monitoreo (5 tests)
   - RF-009: Generar reportes detallados (6 tests)
   - RF-010: Cambiar contraseña de usuario (6 tests)
   - RF-011: Exportar reportes a formato PDF (5 tests)
   - RF-012: Gestionar usuarios Administradores (6 tests)
   - RF-013: Asignar credenciales a empleados (5 tests)
   - RF-014: Sincronizar datos Faciales con API (9 tests)

4. **Resumen por Requisito**
   - Tabla con estadísticas de cada requisito
   - Estado de cada requisito (EXITOSO/FALLIDO)

5. **Detalle de Pruebas Individuales**
   - Lista completa de todas las pruebas
   - Estado de cada prueba individual

## 📁 Archivos Generados

- `test/reporte_pruebas_unitarias_YYYY-MM-DD.pdf` - Reporte PDF
- `test_output.txt` - Salida completa de los tests (opcional)

## 🔧 Estructura de Archivos

```
geoface/
├── generate_test_report.bat           # Script para Windows
├── generate_test_report.sh            # Script para Linux/Mac
└── test/
    ├── generate_test_report.dart      # Script principal
    ├── test_report_generator.dart     # Generador de PDF
    ├── INSTRUCCIONES_REPORTE.md       # Instrucciones detalladas
    └── reporte_pruebas_unitarias_*.pdf # Reporte generado
```

## 📝 Ejemplo de Salida

```
========================================
  GENERADOR DE REPORTE DE PRUEBAS
  Sistema GeoFace
========================================

[1/3] Ejecutando pruebas unitarias...
✓ Todas las pruebas pasaron exitosamente!

[2/3] Generando reporte PDF...
🚀 Iniciando ejecución de pruebas unitarias...

📊 Resumen de resultados:
   Total de pruebas: 85
   Pruebas exitosas: 85
   Pruebas fallidas: 0
   Tasa de éxito: 100.0%

📄 Generando reporte PDF...
✅ Reporte PDF generado exitosamente en: test/reporte_pruebas_unitarias_2025-11-07.pdf

[3/3] Proceso completado!

========================================
  RESUMEN
========================================
  - Reporte PDF generado en: test\reporte_pruebas_unitarias_*.pdf
  - Salida de tests guardada en: test_output.txt
```

## 🎯 Ventajas

- **Automatización completa**: Un solo comando ejecuta todo
- **Reporte profesional**: Formato listo para presentación
- **Trazabilidad**: Incluye fecha y hora de ejecución
- **Detalle completo**: Todas las pruebas documentadas
- **Fácil de compartir**: Formato PDF estándar

## 📖 Documentación Adicional

- Ver `test/INSTRUCCIONES_REPORTE.md` para instrucciones detalladas
- Ver `test/README.md` para información sobre las pruebas unitarias

## 🐛 Solución de Problemas

Si encuentras problemas, verifica:
1. ✅ Flutter y Dart están instalados y en el PATH
2. ✅ Las dependencias están instaladas (`flutter pub get`)
3. ✅ Estás en el directorio correcto (`geoface/`)
4. ✅ Tienes permisos de escritura en la carpeta `test/`

## 📞 Soporte

Para problemas o preguntas, consulta la documentación del proyecto o contacta al equipo de desarrollo.


