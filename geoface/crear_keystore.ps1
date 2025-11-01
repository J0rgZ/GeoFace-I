# Script para crear un keystore nuevo para GeoFace
# Ejecuta este script en PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creación de Keystore para GeoFace" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Buscar keytool
$keytoolPaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "$env:ANDROID_HOME\bin\keytool.exe",
    "${env:ProgramFiles}\Android\Android Studio\jbr\bin\keytool.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe",
    "${env:LocalAppData}\Android\Sdk\build-tools\*\keytool.exe"
)

$keytool = $null
foreach ($path in $keytoolPaths) {
    if (Test-Path $path) {
        $keytool = (Resolve-Path $path).Path
        break
    }
}

# Buscar en subdirectorios de build-tools
if (-not $keytool) {
    $buildToolsDirs = Get-ChildItem -Path "${env:LocalAppData}\Android\Sdk\build-tools" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($dir in $buildToolsDirs) {
        $keytoolPath = Join-Path $dir.FullName "keytool.exe"
        if (Test-Path $keytoolPath) {
            $keytool = $keytoolPath
            break
        }
    }
}

if (-not $keytool) {
    Write-Host "ERROR: No se encontró keytool.exe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, instala Java JDK o Android Studio" -ForegroundColor Yellow
    Write-Host "O proporciona la ruta completa a keytool.exe manualmente" -ForegroundColor Yellow
    exit 1
}

Write-Host "Keytool encontrado en: $keytool" -ForegroundColor Green
Write-Host ""

# Solicitar información
Write-Host "Información requerida para crear el keystore:" -ForegroundColor Yellow
Write-Host ""

$keystorePassword = Read-Host "Contraseña del Keystore" -AsSecureString
$keystorePasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePassword))

$keyPasswordConfirm = Read-Host "Confirma la contraseña del Keystore" -AsSecureString
$keyPasswordConfirmText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPasswordConfirm))

if ($keystorePasswordText -ne $keyPasswordConfirmText) {
    Write-Host "ERROR: Las contraseñas no coinciden" -ForegroundColor Red
    exit 1
}

$keyAlias = Read-Host "Alias de la clave (ej: upload, release, Jorge)" 
if ([string]::IsNullOrWhiteSpace($keyAlias)) {
    $keyAlias = "upload"
    Write-Host "Usando alias por defecto: upload" -ForegroundColor Yellow
}

# Información personal (requerida por keytool)
Write-Host ""
Write-Host "Información personal (requerida para el certificado):" -ForegroundColor Yellow
$nombre = Read-Host "Nombre completo"
$organizacion = Read-Host "Nombre de organización" 
$ciudad = Read-Host "Ciudad"
$estado = Read-Host "Estado/Provincia"
$pais = Read-Host "Código de país (2 letras, ej: PE, MX, ES)"

$validity = 10000  # ~27 años
$keystoreFile = "mi-clave-lanzamiento.jks"

Write-Host ""
Write-Host "Creando keystore..." -ForegroundColor Cyan

# Construir el comando keytool
# Nota: -dname debe estar entre comillas para manejar espacios en nombres
$dname = "CN=$nombre, OU=$organizacion, O=$organizacion, L=$ciudad, ST=$estado, C=$pais"

try {
    # Construir el DN (Distinguished Name) escapando correctamente las comas
    $dnameValue = "CN=$nombre, OU=$organizacion, O=$organizacion, L=$ciudad, ST=$estado, C=$pais"
    
    # Ejecutar usando & (call operator) para mejor manejo de argumentos complejos
    $result = & $keytool -genkey -v `
        -keystore $keystoreFile `
        -keyalg RSA `
        -keysize 2048 `
        -validity $validity `
        -alias $keyAlias `
        -storepass $keystorePasswordText `
        -keypass $keystorePasswordText `
        -dname $dnameValue 2>&1
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "¡Keystore creado exitosamente!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Archivo: $keystoreFile" -ForegroundColor Cyan
        Write-Host "Alias: $keyAlias" -ForegroundColor Cyan
        Write-Host ""
        
        # Crear archivo key.properties
        $keyPropertiesContent = @"
storeFile=../mi-clave-lanzamiento.jks
keyAlias=$keyAlias
storePassword=$keystorePasswordText
keyPassword=$keystorePasswordText
"@
        
        $keyPropertiesPath = "android\key.properties"
        $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
        Write-Host "Archivo key.properties creado en: $keyPropertiesPath" -ForegroundColor Green
        Write-Host ""
        
        # Crear archivo de información segura
        $infoContent = @"
========================================
INFORMACIÓN DEL KEYSTORE - GUARDAR DE FORMA SEGURA
========================================

FECHA DE CREACIÓN: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

ARCHIVO KEYSTORE: mi-clave-lanzamiento.jks
UBICACIÓN: Raíz del proyecto (geoface/mi-clave-lanzamiento.jks)

ALIAS: $keyAlias
CONTRASEÑA DEL KEYSTORE: $keystorePasswordText
CONTRASEÑA DE LA CLAVE: $keystorePasswordText

INFORMACIÓN DEL CERTIFICADO:
- Nombre: $nombre
- Organización: $organizacion
- Ciudad: $ciudad
- Estado: $estado
- País: $pais
- Validez: $validity días (~27 años)

========================================
ADVERTENCIAS IMPORTANTES:
========================================
1. GUARDA ESTA INFORMACIÓN EN UN LUGAR SEGURO
2. Si pierdes el keystore o las contraseñas, NO podrás actualizar tu app en Play Store
3. NO subas el archivo .jks al repositorio
4. HAZ BACKUP del archivo .jks en un lugar seguro (USB, cloud encriptado, etc.)
5. Si publicas la app, DEBES usar SIEMPRE este mismo keystore para todas las actualizaciones

========================================
"@
        
        $infoPath = "INFORMACION_KEYSTORE.txt"
        $infoContent | Out-File -FilePath $infoPath -Encoding UTF8
        Write-Host "Archivo de información creado: $infoPath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "¡IMPORTANTE!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "1. Guarda el archivo '$infoPath' en un lugar SEGURO" -ForegroundColor Yellow
        Write-Host "2. Haz BACKUP del archivo '$keystoreFile'" -ForegroundColor Yellow
        Write-Host "3. ELIMINA '$infoPath' después de guardarlo en lugar seguro" -ForegroundColor Yellow
        Write-Host "4. NO subas estos archivos al repositorio" -ForegroundColor Yellow
        Write-Host ""
        
    } else {
        Write-Host ""
        Write-Host "ERROR: Error al crear el keystore" -ForegroundColor Red
        Write-Host "Salida del comando:" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($result) {
        Write-Host "Salida del comando:" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Red
    }
    exit 1
}

Write-Host "Proceso completado. Ahora puedes ejecutar:" -ForegroundColor Green
Write-Host "  flutter build appbundle --release" -ForegroundColor Cyan
Write-Host ""

