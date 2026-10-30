/// Base exception thrown by the data layer when the backend responds with an error.
class ServerException implements Exception {
  ServerException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ServerException: $message';
}

/// Exception thrown when cached/local data is unavailable or invalid.
class CacheException implements Exception {
  CacheException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when the device is offline or a request fails.
class NetworkException implements Exception {
  NetworkException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'NetworkException: $message';
}


