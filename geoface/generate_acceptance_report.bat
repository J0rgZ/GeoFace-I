@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   GENERADOR DE REPORTE DE ACEPTACION
echo   Sistema GeoFace
echo ========================================
echo.

echo Paso 1: (Opcional) Ejecutar pruebas manuales.
echo   * Asegure haber recopilado evidencias antes de generar el reporte.
echo.

echo Paso 2: Generar reporte PDF...
dart run test/generate_acceptance_report.dart
if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo generar el reporte de aceptación.
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo   REPORTE GENERADO CORRECTAMENTE

dir test\reporte_aceptacion_*.pdf

echo.
pause


