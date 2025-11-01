# GeoFace - Sistema de Control de Asistencia

GeoFace es una aplicación móvil desarrollada en Flutter que permite el control de asistencia laboral mediante reconocimiento facial biométrico y verificación de geolocalización.

## 🎯 Características Principales

- **Reconocimiento Facial Biométrico**: Sistema de verificación de identidad mediante captura y comparación de imágenes faciales
- **Geolocalización**: Verificación de ubicación para asegurar que los empleados registren asistencia desde ubicaciones autorizadas
- **Control de Asistencia**: Registro automático de entrada y salida con captura facial y verificación de ubicación
- **Gestión de Empleados**: Administración completa de empleados, sedes y usuarios
- **Reportes y Estadísticas**: Visualización de registros de asistencia y estadísticas laborales
- **Generación de PDFs**: Exportación de reportes en formato PDF

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.7.2+**: Framework de desarrollo multiplataforma
- **Firebase**: 
  - Firebase Authentication (autenticación de usuarios)
  - Cloud Firestore (base de datos)
  - Firebase Storage (almacenamiento de imágenes)
- **Google Maps**: Servicios de geolocalización y mapas
- **ML Kit**: Reconocimiento facial
- **Camera**: Captura de imágenes

## 📱 Permisos Requeridos

La aplicación requiere los siguientes permisos para funcionar correctamente:

- **Cámara**: Para capturar imágenes faciales en el registro biométrico y verificación de asistencia
- **Ubicación precisa**: Para verificar que el empleado se encuentra en la ubicación autorizada
- **Ubicación en segundo plano**: Para verificación continua durante el horario laboral
- **Almacenamiento**: Para guardar temporalmente imágenes antes de subirlas al servidor

## 📋 Requisitos del Sistema

- **Android**: Mínimo Android 6.0 (API 23)
- **Dispositivo**: Cámara frontal funcional, GPS activo
- **Conexión**: Internet requerida para sincronización con servidores

## 📄 Documentación Legal

- [Política de Privacidad](POLITICA_DE_PRIVACIDAD.md)
- [Términos y Condiciones](TERMINOS_Y_CONDICIONES.md)
- [Checklist para Play Store](CHECKLIST_PLAY_STORE.md)

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK 3.7.2 o superior
- Android Studio o VS Code con extensiones de Flutter
- Cuenta de Firebase configurada
- Archivo `google-services.json` configurado

### Pasos de Instalación

1. Clonar el repositorio:
```bash
git clone [url-del-repositorio]
cd geoface
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Configurar Firebase:
   - Agregar `google-services.json` en `android/app/`
   - Verificar configuración en `firebase_options.dart`

4. Configurar signing para producción:
   - Crear archivo `android/key.properties` con las credenciales del keystore
   - El keystore debe estar en `android/app/mi-clave-lanzamiento.jks`

5. Ejecutar la aplicación:
```bash
flutter run
```

## 🏗️ Estructura del Proyecto

```
lib/
├── controllers/     # Controladores de estado y lógica de negocio
├── models/         # Modelos de datos
├── services/       # Servicios de Firebase y APIs
├── views/          # Pantallas y widgets de la UI
├── themes/         # Temas de la aplicación
├── utils/          # Utilidades y helpers
├── routes.dart     # Configuración de rutas
└── main.dart       # Punto de entrada de la aplicación
```

## 📦 Construcción para Producción

### Android (AAB para Play Store)

```bash
flutter build appbundle --release
```

El archivo AAB se generará en `build/app/outputs/bundle/release/app-release.aab`

### Verificación Pre-lanzamiento

Antes de publicar en Play Store, consulta el [Checklist para Play Store](CHECKLIST_PLAY_STORE.md) para asegurar que todos los requisitos están cumplidos.

## 🔒 Seguridad y Privacidad

- Los datos se transmiten y almacenan utilizando encriptación estándar de la industria
- Los datos biométricos se almacenan de forma segura en Firebase Storage
- La autenticación utiliza Firebase Authentication con medidas de seguridad robustas
- Todos los datos personales se manejan según nuestra [Política de Privacidad](POLITICA_DE_PRIVACIDAD.md)

## 👥 Autores

- Brayar Lopez Catunta
- Jorge Luis Briceño Diaz

## 📝 Licencia

[Especificar licencia]

## 📞 Soporte

Para soporte técnico o consultas, contactar a: [email de contacto]

---

**Importante**: Esta aplicación recopila y procesa datos biométricos y de ubicación. Por favor, revisa nuestra Política de Privacidad antes de utilizar la aplicación.
