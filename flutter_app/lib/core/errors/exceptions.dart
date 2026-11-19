class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Unable to connect to the backend server. Please verify your Backend URL in Settings.']);
}

class ApiException extends AppException {
  ApiException(super.message, {super.statusCode});
}
