import 'package:flutter/foundation.dart';

/// A service class that provides centralized logging functionality.
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  /// Log an error with optional stack trace and additional context
  void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' | Context: $context' : '';
    final errorInfo = error != null ? ' | Error: $error' : '';

    debugPrint('❌ ERROR [$timestamp]$contextInfo: $message$errorInfo');

    if (stackTrace != null) {
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
    }
  }

  /// Log a warning message
  void logWarning(String message, [String? context]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' | Context: $context' : '';

    debugPrint('⚠️ WARNING [$timestamp]$contextInfo: $message');
  }

  /// Log an info message
  void logInfo(String message, [String? context]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' | Context: $context' : '';

    debugPrint('ℹ️ INFO [$timestamp]$contextInfo: $message');
  }

  /// Log a debug message (only in debug mode)
  void logDebug(String message, [String? context]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final contextInfo = context != null ? ' | Context: $context' : '';

      debugPrint('🔍 DEBUG [$timestamp]$contextInfo: $message');
    }
  }
}
