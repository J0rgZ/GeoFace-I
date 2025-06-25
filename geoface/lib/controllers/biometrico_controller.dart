import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// No necesitamos el modelo Biometrico aquí si manejamos los datos directamente.
// Si lo usas en otro lugar, puedes mantenerlo.

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
  bool get isCameraInitialized => _isCameraInitialized;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;

  BiometricoController() {
    // Constructor
  }

  // --- MÉTODOS DE LA CÁMARA ---

  Future<void> initCamera() async {
    if (_isCameraInitialized) return; // Evitar reinicialización
    
    _errorMessage = null;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No se encontraron cámaras disponibles.');
      }
      
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high, // Usar alta resolución para mejor calidad de reconocimiento
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
  
  Future<void> stopCamera() async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      await cameraController!.dispose();
      cameraController = null;
      _isCameraInitialized = false;
      notifyListeners();
    }
  }
  
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

  // --- MÉTODOS DE FIREBASE (CRUD PARA MÚLTIPLES IMÁGENES) ---

  /// Obtiene las URLs de las imágenes biométricas de un empleado.
  /// Devuelve una lista vacía si no hay registro.
  Future<List<String>> getBiometricoUrlsByEmpleadoId(String empleadoId) async {
    try {
      final doc = await _findBiometricDocument(empleadoId);
      if (doc == null || !doc.exists) {
        return [];
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

  /// Registra o actualiza el biométrico de un empleado con un conjunto de imágenes.
  /// Sube los archivos a Storage y guarda/actualiza el documento en Firestore.
  Future<bool> registerOrUpdateBiometricoWithMultipleFiles(String empleadoId, List<File> images) async {
    if (images.length != 3) {
      _errorMessage = "Se requieren exactamente 3 imágenes.";
      notifyListeners();
      return false;
    }

    _setProcessing(true);
    
    try {
      // 1. Antes de subir las nuevas, elimina las imágenes y el documento antiguos.
      await deleteBiometricoByEmpleadoId(empleadoId, fromUpdate: true);

      // 2. Sube las nuevas imágenes a Firebase Storage
      final List<String> newImageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final String fileName = '${const Uuid().v4()}.jpg';
        final Reference ref = _storage.ref().child('biometricos/$empleadoId/$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        newImageUrls.add(downloadUrl);
      }

      // 3. Crea o actualiza el documento en Firestore
      // Usamos el ID del empleado como ID del documento para asegurar que solo haya uno.
      await _firestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': newImageUrls,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fechaModificacion': FieldValue.serverTimestamp(),
      });

      // 4. (Opcional) Actualizar un flag en el documento del empleado
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
  
  /// Elimina el registro biométrico completo de un empleado.
  Future<bool> deleteBiometricoByEmpleadoId(String empleadoId, {bool fromUpdate = false}) async {
    // 'fromUpdate' evita notificar a la UI cuando es una operación interna.
    if (!fromUpdate) _setProcessing(true);

    try {
      final doc = await _findBiometricDocument(empleadoId);
      if (doc == null || !doc.exists) {
        if (!fromUpdate) _setProcessing(false);
        return true; // No había nada que borrar, operación exitosa.
      }

      final data = doc.data() as Map<String, dynamic>;
      final urls = List<String>.from(data['datosFaciales'] ?? []);

      // 1. Eliminar imágenes de Firebase Storage
      for (final url in urls) {
        try {
          // No uses el ID, usa la URL completa que es más robusta
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          debugPrint("No se pudo borrar la imagen $url: $e. Puede que ya no exista.");
        }
      }

      // 2. Eliminar el documento de Firestore
      await doc.reference.delete();
      
      // 3. (Opcional) Actualizar flag en el empleado
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

  /// Busca el documento biométrico de un empleado.
  Future<DocumentSnapshot?> _findBiometricDocument(String empleadoId) async {
    // Como ahora el ID del documento es el ID del empleado, la búsqueda es directa y más rápida.
    final docRef = _firestore.collection('biometricos').doc(empleadoId);
    final doc = await docRef.get();
    return doc.exists ? doc : null;
  }
  
  /// Helper para gestionar el estado de procesamiento y notificar a los listeners.
  void _setProcessing(bool value) {
    _isProcessing = value;
    if (!_isProcessing) {
      _errorMessage = null; // Limpiar errores al finalizar una operación
    }
    notifyListeners();
  }

  // --- LIMPIEZA ---
  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }
}