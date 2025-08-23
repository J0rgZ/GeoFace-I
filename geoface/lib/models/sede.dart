// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Sedes
// @Autor:        Brayar Lopez Catunta
// @Descripción:  Define el modelo de datos para la clase `Sede`. Esta clase
//               representa una sucursal o ubicación física de la empresa,
//               incluyendo su nombre, dirección, geolocalización y estado
//               operativo. El modelo es inmutable y está diseñado para manejar
//               la serialización y deserialización de datos desde y hacia JSON.
//
// @NombreModelo: Sede
// @Ubicacion:    lib/models/sede.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

// Representa el modelo de datos para una Sede o sucursal de la empresa.
//
// Esta clase es inmutable. Si necesitas modificar una sede, no cambies
// sus propiedades directamente; en su lugar, crea una nueva instancia
// con los datos actualizados usando el método `copyWith`.
class Sede {
  // Se define un valor por defecto para el radio. Así evitamos "números mágicos" en el código.
  static const int kRadioPermitidoPorDefecto = 100;

  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final int radioPermitido;
  final bool activa;
  final DateTime fechaCreacion;
  // Es opcional porque una sede nueva no tiene modificaciones.
  final DateTime? fechaModificacion;

  Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.radioPermitido,
    required this.activa,
    required this.fechaCreacion,
    this.fechaModificacion,
  });

  // Construye una instancia de Sede a partir de un mapa JSON.
  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      // Si el radio no viene en el JSON, usamos el valor por defecto para evitar errores.
      radioPermitido: json['radioPermitido'] ?? kRadioPermitidoPorDefecto,
      activa: json['activa'],
      // Se convierte el texto de fecha en formato ISO a un objeto DateTime.
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      // Se maneja el caso en que la fecha de modificación pueda no existir.
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  // Convierte la instancia de Sede a un mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radioPermitido': radioPermitido,
      'activa': activa,
      // Se convierte DateTime a un string en formato estándar ISO 8601 para guardarlo.
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  // Crea una copia de la instancia actual, permitiendo modificar solo algunos valores.
  // Es la forma correcta de "actualizar" un objeto inmutable.
  Sede copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    int? radioPermitido,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Sede(
      // Si se proporciona un nuevo valor, se usa; si no, se mantiene el actual (this.id).
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      radioPermitido: radioPermitido ?? this.radioPermitido,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      // Al hacer una copia, se asume una modificación, por lo que se actualiza la fecha.
      fechaModificacion: fechaModificacion ?? DateTime.now(),
    );
  }

  // Crea una instancia "vacía" de Sede.
  // Es muy útil para inicializar estados en la UI antes de que lleguen los datos reales,
  // y así evitar errores por valores nulos.
  static Sede empty() {
    return Sede(
      id: '',
      nombre: 'Sede no encontrada',
      direccion: '',
      latitud: 0.0,
      longitud: 0.0,
      radioPermitido: 0,
      activa: false,
      fechaCreacion: DateTime.now(),
      fechaModificacion: null,
    );
  }
}