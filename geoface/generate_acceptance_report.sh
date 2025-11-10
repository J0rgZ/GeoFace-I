#!/bin/bash

echo "========================================"
echo "  GENERADOR DE REPORTE DE ACEPTACION"
echo "  Sistema GeoFace"
echo "========================================"
echo ""

echo "Paso 1 (opcional): Asegúrate de contar con evidencias actualizadas." 
echo "Paso 2: Generando reporte PDF..."
echo ""
dart run test/generate_acceptance_report.dart
if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: No se pudo generar el reporte de aceptación"
  exit 1
fi

echo ""
echo "========================================"
echo "  REPORTE GENERADO CORRECTAMENTE"
echo "========================================"
ls test/reporte_aceptacion_*.pdf 2>/dev/null || echo "Aún no se generó ningún archivo"


