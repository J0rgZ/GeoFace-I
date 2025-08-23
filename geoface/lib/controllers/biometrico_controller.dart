// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Datos Biométricos
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica para la gestión de datos
//               biométricos faciales de los empleados. Se encarga de inicializar
//               y controlar la cámara del dispositivo para capturar imágenes,
//               y de realizar las operaciones CRUD (Crear, Leer, Actualizar,
//               Eliminar) en Firebase Storage y Firestore para persistir
//               dichos datos.
//
// @NombreControlador: BiometricoController
// @Ubicacion:    lib/controllers/biometrico_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BiometricoController extends ChangeNotifier {
  // --- DEPENDENCIAS ---
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- ESTADO DE LA CÁMARA ---
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  
  // --- ESTADO GENERAL ---
  String? _errorMessage;
  bool _isProcessing = false;
  
  // --- GETTERS PÚBLICOS ---
  // Permiten que la UI acceda al estado del controlador de forma segura.
  bool get isCameraInitialized => _isCameraInitialized;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;

  BiometricoController() {
    // Constructor
  }

  // --- MÉTODOS DE LA CÁMARA ---

  // Inicializa la cámara frontal del dispositivo para la captura de imágenes.
  Future<void> initCamera() async {
    if (_isCameraInitialized) return; // Evita reinicializaciones innecesarias.
    
    _errorMessage = null;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No se encontraron cámaras disponibles.');
      }
      
      // Se prioriza la cámara frontal, que es la estándar para reconocimiento facial.
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high, // Alta resolución para mejor calidad de reconocimiento.
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      _isCameraInitialized = true;
    } catch (e) {
      _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
      _isCameraInitialized = false;
    } finally {
      notifyListeners();
    }
  }
  
  // Libera los recursos de la cámara cuando ya no se necesita.
  // Es crucial para evitar fugas de memoria y problemas de rendimiento.
  Future<void> stopCamera() async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      await cameraController!.dispose();
      cameraController = null;
      _isCameraInitialized = false;
      notifyListeners();
    }
  }
  
  // Captura una foto usando el controlador de la cámara y la devuelve como un archivo (File).
  Future<File?> takePicture() async {
    if (!_isCameraInitialized || cameraController == null) {
      _errorMessage = 'La cámara no está lista.';
      notifyListeners();
      return null;
    }
    
    try {
      final XFile imageXFile = await cameraController!.takePicture();
      return File(imageXFile.path);
    } catch (e) {
      _errorMessage = 'Error al capturar la foto: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // --- MÉTODOS DE FIREBASE ---

  // Obtiene las URLs de las imágenes biométricas de un empleado desde Firestore.
  Future<List<String>> getBiometricoUrlsByEmpleadoId(String empleadoId) async {
    try {
      final doc = await _findBiometricDocument(empleadoId);
      if (doc == null || !doc.exists) {
        return []; // Devuelve una lista vacía si no hay registro.
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final urls = List<String>.from(data['datosFaciales'] ?? []);
      return urls;

    } catch (e) {
      _errorMessage = 'Error al obtener datos biométricos: $e';
      notifyListeners();
      return [];
    }
  }

  // Registra o actualiza el biométrico de un empleado con un conjunto de imágenes.
  Future<bool> registerOrUpdateBiometricoWithMultipleFiles(String empleadoId, List<File> images) async {
    if (images.length != 3) {
      _errorMessage = "Se requieren exactamente 3 imágenes.";
      notifyListeners();
      return false;
    }

    _setProcessing(true);
    
    try {
      // 1. Antes de subir las nuevas imágenes, se elimina cualquier registro biométrico anterior
      // para mantener la consistencia y evitar datos huérfanos.
      await deleteBiometricoByEmpleadoId(empleadoId, fromUpdate: true);

      // 2. Se suben las nuevas imágenes a Firebase Storage.
      final List<String> newImageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final String fileName = '${const Uuid().v4()}.jpg';
        final Reference ref = _storage.ref().child('biometricos/$empleadoId/$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        newImageUrls.add(downloadUrl);
      }

      // 3. Se crea o actualiza el documento en Firestore usando el ID del empleado como clave.
      // Esto asegura que cada empleado tenga un único documento biométrico.
      await _firestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': newImageUrls,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fechaModificacion': FieldValue.serverTimestamp(),
      });

      // 4. Se actualiza el flag en el documento del empleado para reflejar que tiene datos biométricos.
      await _firestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': true,
        'fechaModificacion': FieldValue.serverTimestamp(),
      });

      _setProcessing(false);
      return true;

    } catch (e) {
      _errorMessage = 'Error al guardar el registro: ${e.toString()}';
      _setProcessing(false);
      return false;
    }
  }
  
  // Elimina el registro biométrico completo de un empleado.
  Future<bool> deleteBiometricoByEmpleadoId(String empleadoId, {bool fromUpdate = false}) async {
    // El parámetro `fromUpdate` evita notificar a la UI cuando es una operación interna de actualización.
    if (!fromUpdate) _setProcessing(true);

    try {
      final doc = await _findBiometricDocument(empleadoId);
      if (doc == null || !doc.exists) {
        if (!fromUpdate) _setProcessing(false);
        return true; // No había nada que borrar, se considera una operación exitosa.
      }

      final data = doc.data() as Map<String, dynamic>;
      final urls = List<String>.from(data['datosFaciales'] ?? []);

      // 1. Se eliminan las imágenes de Firebase Storage.
      for (final url in urls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Se ignora el error si la imagen ya no existe, para que el proceso no falle.
          debugPrint("No se pudo borrar la imagen $url: $e. Puede que ya no exista.");
        }
      }

      // 2. Se elimina el documento de Firestore.
      await doc.reference.delete();
      
      // 3. Se actualiza el flag en el documento del empleado.
      await _firestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': false,
        'fechaModificacion': FieldValue.serverTimestamp(),
      });

      if (!fromUpdate) _setProcessing(false);
      return true;

    } catch (e) {
      _errorMessage = 'Error al eliminar el registro: ${e.toString()}';
      if (!fromUpdate) _setProcessing(false);
      return false;
    }
  }

  // --- MÉTODOS PRIVADOS AUXILIARES ---

  // Busca el documento biométrico de un empleado.
  // La búsqueda es directa y eficiente al usar el ID del empleado como ID del documento.
  Future<DocumentSnapshot?> _findBiometricDocument(String empleadoId) async {
    final docRef = _firestore.collection('biometricos').doc(empleadoId);
    final doc = await docRef.get();
    return doc.exists ? doc : null;
  }
  
  // Método centralizado para gestionar el estado de procesamiento.
  void _setProcessing(bool value) {
    _isProcessing = value;
    if (!_isProcessing) {
      _errorMessage = null; // Limpia errores al finalizar una operación.
    }
    notifyListeners();
  }

  // --- LIMPIEZA ---
  // Se asegura de liberar la cámara al destruir el controlador para evitar fugas de memoria.
  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }
}