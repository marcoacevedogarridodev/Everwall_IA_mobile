/// Excepción tipada que normaliza los errores de Dio/backend en un mensaje
/// legible para mostrar en UI, más el status code y el payload crudo por
/// si algún caller necesita inspeccionar detalles (ej. errores de campo).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}
