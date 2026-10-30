import 'package:equatable/equatable.dart';

/// Base failure type shared across all features.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;

  /// Stable machine-readable code (e.g. `group-full`) used for localized text.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// The backend reported an error.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Cached data cannot be used.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// The device is offline or the request failed at network level.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// An authentication operation failed.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// The caller is not allowed to perform the operation.
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}
