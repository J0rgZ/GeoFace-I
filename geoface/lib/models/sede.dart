/// Representa el modelo de datos para una Sede o sucursal de la empresa.
///
/// Esta clase es inmutable, lo que significa que una vez que se crea una instancia
/// de Sede sus propiedades no pueden cambiar. Para realizar una modificación
/// se debe crear una nueva instancia a través del método `copyWith`.
class Sede {
  // Principio: "Evitemos los números mágicos".
  // Se define el 100 como una constante para que tenga un nombre claro.
  static const int kRadioPermitidoPorDefecto = 100;

  /// Identificador único de la sede (ej: UUID).
  final String id;

  /// Nombre comercial o descriptivo de la sede.
  final String nombre;

  /// Dirección física de la sede.
  final String direccion;

  /// Coordenada de latitud para la geolocalización.
  final double latitud;

  /// Coordenada de longitud para la geolocalización.
  final double longitud;

  /// Distancia en metros a la redonda desde la ubicación de la sede
  /// donde se permiten ciertas acciones (ej: registrar asistencia).
  final int radioPermitido;

  /// Indica si la sede está operativa o no.
  final bool activa;

  /// Fecha y hora en que se registró la sede por primera vez.
  final DateTime fechaCreacion;

  /// Fecha y hora de la última modificación de los datos de la sede.
  /// Es opcional (`nullable`) porque una sede recién creada no tiene modificaciones.
  final DateTime? fechaModificacion;

  /// Constructor principal para crear una instancia de [Sede].
  ///
  /// Requiere todos los parámetros, excepto [fechaModificacion] que es opcional.
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

  /// Construye una instancia de [Sede] a partir de un mapa (generalmente de un JSON).
  ///
  /// Este es un "factory constructor" que se utiliza para la deserialización de datos,
  /// por ejemplo, al recibir una respuesta de una API.
  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      // Si 'radioPermitido' no viene en el JSON, se le asigna el valor por defecto.
      // Esto previene errores y asegura consistencia.
      radioPermitido: json['radioPermitido'] ?? kRadioPermitidoPorDefecto,
      activa: json['activa'],
      // Convierte el string de fecha en formato ISO a un objeto DateTime.
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      // Maneja el caso en que la fecha de modificación sea nula.
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  /// Convierte la instancia actual de [Sede] a un mapa.
  ///
  /// Este método es útil para la serialización de datos, es decir, para
  /// convertir el objeto a un formato que pueda ser fácilmente guardado como JSON
  /// o enviado a una API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radioPermitido': radioPermitido,
      'activa': activa,
      // Convierte el objeto DateTime a un string en formato estándar ISO 8601.
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crea una copia de la instancia actual de [Sede] con la posibilidad de
  /// modificar algunos de sus valores.
  ///
  /// Dado que la clase es inmutable, este método es la forma correcta de
  /// "actualizar" una sede. Devuelve un nuevo objeto en lugar de mutar el original.
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
      // Si se proporciona un nuevo valor, se usa; si no, se mantiene el actual (`this.id`).
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      radioPermitido: radioPermitido ?? this.radioPermitido,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      // Al hacer una copia que modifica algún dato, se actualiza la
      // fecha de modificación a la fecha y hora actuales.
      fechaModificacion: fechaModificacion ?? DateTime.now(),
    );
  }

  /// Crea una instancia de [Sede] con valores por defecto o "vacíos".
  ///
  /// Es útil para inicializar variables o estados en la UI antes de que los
  /// datos reales sean cargados, evitando así errores por valores nulos.
  static Sede empty() {
    return Sede(
      id: '',
      // Se utiliza un nombre descriptivo para indicar que es un objeto placeholder.
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