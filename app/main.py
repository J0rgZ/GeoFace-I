# ==============================================================================
# API de Reconocimiento Facial - GeoFace
# Versión para Azure App Service
# ==============================================================================

import os
import sys
import shutil
import requests
import firebase_admin
from firebase_admin import credentials, firestore
import cv2
import numpy as np
from PIL import Image, ImageStat
from flask import Flask, request, jsonify
import uuid
import logging
from datetime import datetime

# --- CONFIGURACIÓN DE LOGGING ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app/logs/api.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# --- CONFIGURACIÓN GLOBAL ---
# Buscar archivo Firebase: primero en variable de entorno, luego en archivos comunes
SERVICE_ACCOUNT_KEY = os.getenv('FIREBASE_KEY_PATH', None)
if not SERVICE_ACCOUNT_KEY:
    # Buscar archivo Firebase en el directorio actual
    firebase_files = [f for f in os.listdir('.') if f.endswith('.json') and 'firebase' in f.lower()]
    if firebase_files:
        SERVICE_ACCOUNT_KEY = firebase_files[0]
    else:
        SERVICE_ACCOUNT_KEY = 'geoface-firebase-adminsdk.json'

DB_PATH = "employee_face_db"
UPLOADS_DIR = "app/uploads"

# Crear directorios necesarios
os.makedirs(DB_PATH, exist_ok=True)
os.makedirs(UPLOADS_DIR, exist_ok=True)
os.makedirs('app/logs', exist_ok=True)

# --- INICIALIZACIÓN DE FLASK ---
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max

# --- FUNCIONES DE INFRAESTRUCTURA (Firebase y Sincronización) ---

def initialize_firebase():
    """Inicializa la app de Firebase usando la clave de servicio."""
    try:
        if not firebase_admin._apps:
            if not os.path.exists(SERVICE_ACCOUNT_KEY):
                logger.error(f"❌ Archivo Firebase no encontrado: {SERVICE_ACCOUNT_KEY}")
                raise FileNotFoundError(f"Archivo Firebase no encontrado: {SERVICE_ACCOUNT_KEY}")
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
            firebase_admin.initialize_app(cred)
            logger.info("✅ Conexión con Firebase establecida correctamente.")
        else:
            logger.info("ℹ️ Firebase App ya estaba inicializada.")
    except Exception as e:
        logger.error(f"❌ Error al inicializar Firebase: {e}")
        raise

def sync_face_database_from_firestore():
    """Sincroniza la base de datos facial desde Firestore."""
    logger.info("🔄 Sincronizando base de datos...")
    if os.path.exists(DB_PATH):
        shutil.rmtree(DB_PATH)
    os.makedirs(DB_PATH, exist_ok=True)
    db = firestore.client()
    docs = db.collection('biometricos').stream()
    image_count = 0
    employee_folders = set()
    
    for doc in docs:
        data = doc.to_dict()
        empleado_id = data.get('empleadoId')
        # CORRECCIÓN: Buscar 'datosFaciales' (plural, array) en lugar de 'datoFacial' (singular)
        datos_faciales = data.get('datosFaciales', [])
        
        if not empleado_id or not datos_faciales:
            if not empleado_id:
                logger.warning(f"⚠️  Documento {doc.id} sin empleadoId, omitiendo...")
            elif not datos_faciales:
                logger.warning(f"⚠️  Empleado {empleado_id} sin datosFaciales, omitiendo...")
            continue
        
        # Crear directorio para el empleado
        employee_dir = os.path.join(DB_PATH, empleado_id)
        os.makedirs(employee_dir, exist_ok=True)
        employee_folders.add(empleado_id)
        
        # CORRECCIÓN: Iterar sobre todas las URLs del array datosFaciales
        if isinstance(datos_faciales, list):
            for idx, image_url in enumerate(datos_faciales):
                if not image_url or not isinstance(image_url, str):
                    continue
                try:
                    response = requests.get(image_url, timeout=10)
                    if response.status_code == 200:
                        # Guardar cada imagen con un nombre único (índice + UUID del documento)
                        filename = f"{doc.id}_{idx}.jpg"
                        filepath = os.path.join(employee_dir, filename)
                        with open(filepath, 'wb') as f:
                            f.write(response.content)
                        image_count += 1
                        logger.info(f"✅ Descargada imagen {idx+1}/{len(datos_faciales)} para empleado {empleado_id}")
                    else:
                        logger.warning(f"⚠️  Error HTTP {response.status_code} al descargar {image_url}")
                except Exception as e:
                    logger.error(f"⚠️  Excepción al descargar imagen {idx+1} de {empleado_id}: {e}")
        else:
            logger.warning(f"⚠️  datosFaciales no es un array para empleado {empleado_id}, tipo: {type(datos_faciales)}")
    
    logger.info(f"✅ Sincronización completada: {image_count} imágenes para {len(employee_folders)} empleados.")
    
    # Eliminar cache de DeepFace si existe para forzar regeneración
    cache_file = os.path.join(DB_PATH, "representations_arcface.pkl")
    if os.path.exists(cache_file):
        os.remove(cache_file)
        logger.info("ℹ️ Cache (.pkl) eliminado para forzar regeneración con nuevas imágenes.")

# --- FUNCIONES ANTI-SPOOFING (Análisis de Imagen Completa) ---

def detectar_foto_de_foto(ruta_imagen):
    """
    Detecta si una imagen es una foto de una pantalla o papel usando análisis de imagen.
    """
    try:
        # Cargar la imagen con OpenCV
        img_cv = cv2.imread(ruta_imagen)
        if img_cv is None:
            return False, {"error": "No se pudo cargar la imagen con OpenCV."}

        gray = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)

        # Puntuación y razones para la decisión
        score_spoofing = 0
        razones = []

        # TÉCNICA 1: Detección de patrones de Moiré (comunes en fotos de pantallas)
        f_transform = np.fft.fft2(gray)
        f_shift = np.fft.fftshift(f_transform)
        magnitude_spectrum = 20 * np.log(np.abs(f_shift) + 1)  # +1 para evitar log(0)
        picos_altos = np.sum(magnitude_spectrum > np.mean(magnitude_spectrum) * 1.5)
        if picos_altos > (gray.shape[0] * gray.shape[1] * 0.01):  # Si más del 1% de los puntos son picos
            score_spoofing += 35
            razones.append("Patrones de alta frecuencia detectados (posible pantalla)")

        # TÉCNICA 2: Análisis de reflejos y brillo
        _, thresh = cv2.threshold(gray, 245, 255, cv2.THRESH_BINARY)
        pixeles_brillantes = cv2.countNonZero(thresh)
        porcentaje_brillo = (pixeles_brillantes / gray.size) * 100
        if porcentaje_brillo > 0.5:  # Incluso un 0.5% de reflejo puro es sospechoso
            score_spoofing += 25
            razones.append(f"Reflejos o áreas sobreexpuestas detectadas ({porcentaje_brillo:.2f}%)")

        # TÉCNICA 3: Varianza de color (las fotos de fotos suelen ser más planas)
        pil_img = Image.open(ruta_imagen)
        stat = ImageStat.Stat(pil_img)
        varianza_promedio = sum(stat.var) / len(stat.var) if len(stat.var) > 0 else 0
        if varianza_promedio < 1500:  # Las fotos reales suelen tener alta varianza
            score_spoofing += 20
            razones.append(f"Baja varianza de color ({varianza_promedio:.1f})")

        # TÉCNICA 4: Detección de bordes rectos (marcos de teléfono o papel)
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLinesP(edges, 1, np.pi / 180, threshold=80, minLineLength=100, maxLineGap=10)
        if lines is not None and len(lines) > 2:
            score_spoofing += 20
            razones.append(f"Bordes rectos detectados ({len(lines)}), posible marco de pantalla")

        # Decisión final
        es_spoofing = score_spoofing >= 65  # Umbral de decisión (ajustable)

        detalles = {
            "score": score_spoofing,
            "es_spoofing": es_spoofing,
            "razones": razones if es_spoofing else ["Imagen parece auténtica"]
        }

        return es_spoofing, detalles

    except Exception as e:
        return False, {"error": f"Excepción en análisis de spoofing: {e}"}

# --- FUNCIÓN PRINCIPAL DE IDENTIFICACIÓN ---

def identificar_empleado(ruta_imagen_a_verificar, ruta_db):
    """
    Función de identificación robusta:
    1. Ejecuta un análisis anti-spoofing sobre la imagen completa.
    2. Si la imagen es auténtica, procede con el reconocimiento facial usando DeepFace.
    """
    logger.info("📸 Iniciando proceso de identificación...")

    # PASO 1: Análisis anti-spoofing de la imagen completa
    logger.info("   - (1/2) Realizando análisis de autenticidad de la imagen...")
    es_spoofing, detalles_spoofing = detectar_foto_de_foto(ruta_imagen_a_verificar)

    if es_spoofing:
        razones_str = "; ".join(detalles_spoofing.get("razones", []))
        score = detalles_spoofing.get('score', 'N/A')
        logger.warning(f"   - 🚫 SPOOFING DETECTADO (Score: {score}). Razones: {razones_str}")
        return f"Error: Foto Falsa Detectada. {razones_str}"

    score = detalles_spoofing.get('score', 'N/A')
    logger.info(f"   - ✅ Imagen parece auténtica (Score de spoofing: {score}).")

    # PASO 2: Reconocimiento Facial
    logger.info("   - (2/2) Realizando reconocimiento facial...")
    try:
        # Importar DeepFace solo cuando sea necesario (lazy loading para evitar errores de importación)
        from deepface import DeepFace
        
        # Usamos DeepFace.find para la identificación 1-vs-N
        dfs = DeepFace.find(
            img_path=ruta_imagen_a_verificar,
            db_path=ruta_db,
            model_name='ArcFace',
            detector_backend='retinaface',
            enforce_detection=True,
            silent=True
        )

        # Si no se encuentra ninguna coincidencia
        if not dfs or dfs[0].empty:
            logger.warning("   - ❌ Resultado: Desconocido. No se encontró ninguna coincidencia en la BD.")
            return "Desconocido"

        # Se encontró una coincidencia, devolvemos el ID del empleado
        identidad = dfs[0].iloc[0]
        empleado_id = os.path.basename(os.path.dirname(identidad['identity']))
        distancia = identidad['distance']

        logger.info(f"   - ✅ Resultado: Empleado identificado - ID: {empleado_id} (Distancia: {distancia:.3f})")
        return empleado_id

    except ImportError as e:
        logger.error(f"   - ❌ Error al importar DeepFace: {e}")
        return "Error: El módulo de reconocimiento facial no está disponible. Contacta al administrador."
    except ValueError as e:
        # Error común si DeepFace no detecta una cara
        if "Face could not be detected" in str(e):
            logger.warning("   - ❌ Error de DeepFace: No se detectó un rostro claro.")
            return "Error: No se detectó un rostro claro en la imagen."
        logger.error(f"   - ❌ Error de DeepFace: {e}")
        return f"Error en DeepFace: {e}"
    except Exception as e:
        logger.error(f"   - ❌ Excepción inesperada en DeepFace: {e}")
        return f"Error inesperado durante el reconocimiento: {e}"

# --- ENDPOINTS DE LA API ---

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint de salud para monitoreo."""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "database_synced": os.path.exists(DB_PATH) and len(os.listdir(DB_PATH)) > 0 if os.path.exists(DB_PATH) else False
    }), 200

@app.route('/identificar', methods=['POST'])
def endpoint_identificar():
    """Endpoint principal para identificación facial."""
    if 'face_image' not in request.files:
        return jsonify({"error": "No se envió ningún archivo de imagen.", "empleadoId": None}), 400

    file = request.files['face_image']
    if not file or file.filename == '':
        return jsonify({"error": "Archivo inválido o sin nombre.", "empleadoId": None}), 400

    filename = str(uuid.uuid4()) + os.path.splitext(file.filename)[1]
    filepath = os.path.join(UPLOADS_DIR, filename)
    
    try:
        file.save(filepath)
        resultado_id = identificar_empleado(filepath, DB_PATH)
        os.remove(filepath)

        if "Error" in resultado_id or "Desconocido" in resultado_id:
            status_code = 403 if "Foto Falsa Detectada" in resultado_id else 404
            return jsonify({"error": resultado_id, "empleadoId": None}), status_code
        else:
            return jsonify({"empleadoId": resultado_id, "error": None}), 200
    except Exception as e:
        logger.error(f"Error en endpoint /identificar: {e}")
        if os.path.exists(filepath):
            os.remove(filepath)
        return jsonify({"error": f"Error interno del servidor: {str(e)}", "empleadoId": None}), 500

@app.route('/sync-database', methods=['POST'])
def endpoint_sync():
    """Endpoint para sincronizar la base de datos manualmente."""
    logger.info("🔄 Solicitud de sincronización manual recibida...")
    try:
        sync_face_database_from_firestore()
        return jsonify({"message": "Sincronización completada."}), 200
    except Exception as e:
        logger.error(f"Error al sincronizar: {e}")
        return jsonify({"error": f"Error al sincronizar: {e}"}), 500

# --- INICIALIZACIÓN ---
if __name__ == '__main__':
    # Para desarrollo local
    initialize_firebase()
    sync_face_database_from_firestore()
    app.run(host='0.0.0.0', port=5000, debug=False)
else:
    # Para producción con Gunicorn (Azure App Service)
    try:
        initialize_firebase()
        # La sincronización inicial se puede hacer manualmente o al iniciar
        # sync_face_database_from_firestore()  # Descomentar si quieres sincronizar al iniciar
        logger.info("✅ API inicializada y lista para recibir peticiones")
    except Exception as e:
        logger.error(f"❌ Error al inicializar API: {e}")
        # No lanzar excepción para que el servidor pueda arrancar aunque Firebase falle
        # Se puede sincronizar manualmente después con /sync-database

