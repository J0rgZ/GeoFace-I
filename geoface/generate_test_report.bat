@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   GENERADOR DE REPORTE DE PRUEBAS
echo   Sistema GeoFace
echo ========================================
echo.

echo [1/3] Ejecutando pruebas unitarias...
echo.
flutter test --reporter expanded > test_output.txt 2>&1
set TEST_EXIT_CODE=%errorlevel%

if %TEST_EXIT_CODE% neq 0 (
    echo.
    echo ADVERTENCIA: Algunas pruebas fallaron, pero continuando con la generacion del reporte...
    echo.
) else (
    echo.
    echo ✓ Todas las pruebas pasaron exitosamente!
    echo.
)

echo [2/3] Generando reporte PDF...
echo.
dart run test/generate_test_report.dart
if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo generar el reporte PDF
    pause
    exit /b %errorlevel%
)

echo.
echo [3/3] Proceso completado!
echo.
echo ========================================
echo   RESUMEN
echo ========================================
echo   - Reporte PDF generado en: test\reporte_pruebas_unitarias_*.pdf
echo   - Salida de tests guardada en: test_output.txt
echo.
echo   Para ver los resultados detallados:
echo   type test_output.txt
echo.
pause

