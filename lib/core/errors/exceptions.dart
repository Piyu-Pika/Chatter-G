class ChatterGException implements Exception {
  final String message;

  ChatterGException(this.message);

  @override
  String toString() {
    return 'ChatterGException: $message';
  }
}

class ChatterGError implements Exception {
  final String message;

  ChatterGError(this.message);

  @override
  String toString() {
    return 'ChatterGError: $message';
  }
}
