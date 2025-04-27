import 'package:chatterg/core/errors/exceptions.dart';

class ChatterGFailureException extends ChatterGException {
  ChatterGFailureException(String message) : super(message);
}

class ChatterGFailureError extends ChatterGError {
  ChatterGFailureError(String message) : super(message);
}
