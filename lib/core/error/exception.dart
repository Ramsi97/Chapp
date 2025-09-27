/// ------------------- AUTH EXCEPTIONS -------------------

/// Thrown when Firebase Auth operation fails
class AuthException implements Exception {
  final String message;
  AuthException([this.message = "Authentication failed"]);
}

/// Thrown when OTP verification fails
class OtpException implements Exception {
  final String message;
  OtpException([this.message = "OTP verification failed"]);
}

/// Thrown when login is canceled
class AuthCanceledException implements Exception {
  final String message;
  AuthCanceledException([this.message = "Authentication canceled"]);
}

/// ------------------- SERVER / FIREBASE EXCEPTIONS -------------------

class ServerException implements Exception {
  final String message;
  ServerException([this.message = "Server error occurred"]);
}

class FirestoreException implements Exception {
  final String message;
  FirestoreException([this.message = "Firestore error occurred"]);
}

class StorageException implements Exception {
  final String message;
  StorageException([this.message = "Firebase Storage error occurred"]);
}

/// ------------------- CACHE EXCEPTIONS -------------------

class CacheException implements Exception {
  final String message;
  CacheException([this.message = "Cache error occurred"]);
}

/// ------------------- NETWORK EXCEPTIONS -------------------

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = "No internet connection"]);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = "Request timed out"]);
}

/// ------------------- RESOURCE NOT FOUND -------------------

class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = "Requested resource not found"]);
}

/// ------------------- UNAUTHORIZED / PERMISSION -------------------

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = "Unauthorized"]);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException([this.message = "Forbidden"]);
}

/// ------------------- GENERIC -------------------

class UnknownException implements Exception {
  final String message;
  UnknownException([this.message = "Something went wrong"]);
}
