import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AzureFaceService {
  final String azureEndpoint;
  final String apiKey;

  AzureFaceService({required this.azureEndpoint, required this.apiKey});

  // MÉTODO MODIFICADO: Solo para detectar si hay un rostro.
  // Devuelve 'true' si se detectan rostros, 'false' si no.
  Future<bool> detectarRostroEnImagen(Uint8List imageBytes) async {
    print('Iniciando reconocimiento facial...');

    final uri = Uri.parse('$azureEndpoint/face/v1.0/detect');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': apiKey,
        },
        body: imageBytes,
      );

      if (response.statusCode == 200) {
        final List<dynamic> faces = jsonDecode(response.body);
        if (faces.isNotEmpty) {
          print('¡Rostro detectado exitosamente!');
          return true; // Se encontró al menos un rostro
        } else {
          print('No se detectó ningún rostro en la imagen');
          return false; // No se encontraron rostros
        }
      } else {
        // Imprimir el error de Azure para un mejor diagnóstico
        print('Error detectando rostros: ${response.statusCode} - ${response.body}');
        throw Exception('Error en el servicio de Azure: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la llamada a Azure: $e');
      rethrow; // Propaga el error para que la UI pueda manejarlo
    }
  }

  // Detectar rostros en una imagen y extraer faceId
  Future<List<String>> detectFaces(Uint8List imageBytes) async {
    try {
      final String detectUrl = '$azureEndpoint/face/v1.0/detect';
      
      final Map<String, String> queryParams = {
        'returnFaceId': 'true',
        'recognitionModel': 'recognition_04',
        'detectionModel': 'detection_01',
      };
      
      final Uri uri = Uri.parse(detectUrl).replace(queryParameters: queryParams);
      
      final http.Response response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': apiKey,
        },
        body: imageBytes,
      );
      
      if (response.statusCode == 200) {
        List<dynamic> faces = jsonDecode(response.body);
        return faces.map<String>((face) => face['faceId'] as String).toList();
      } else {
        print('Error detectando rostros: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error en detectFaces: $e');
      return [];
    }
  }

  // Descargar imagen desde URL y convertir a bytes
  Future<Uint8List?> downloadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error descargando imagen: $e');
      return null;
    }
  }

  // Verificar si dos rostros son de la misma persona
  Future<bool> verifyFaces(String faceId1, String faceId2) async {
    try {
      final String verifyUrl = '$azureEndpoint/face/v1.0/verify';
      
      final Map<String, dynamic> body = {
        'faceId1': faceId1,
        'faceId2': faceId2,
      };
      
      final http.Response response = await http.post(
        Uri.parse(verifyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': apiKey,
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final bool isIdentical = result['isIdentical'] ?? false;
        final double confidence = result['confidence'] ?? 0.0;
        
        // Considerar que son la misma persona si la confianza es mayor a 0.7
        return isIdentical && confidence > 0.7;
      } else {
        print('Error verificando rostros: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en verifyFaces: $e');
      return false;
    }
  }
}