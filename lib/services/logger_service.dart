/// Service de journalisation (Logger)
///
/// Fournit des méthodes pour enregistrer les événements, les erreurs et les activités
/// de l'application avec différents niveaux de gravité.
/// Permet le filtrage des logs et l'exportation pour le débogage.
library;

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String tag;
  final Object? data;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    this.data,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  String get formattedTimestamp =>
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);

  String get levelString => level.toString().split('.').last.toUpperCase();

  @override
  String toString() {
    return '[$formattedTimestamp] $levelString - $tag: $message${data != null ? ' - $data' : ''}';
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': levelString,
      'tag': tag,
      'message': message,
      'data': data?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

class LoggerService {
  // Singleton instance
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Configuration
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _printToConsole = true;
  bool _storeInMemory = true;
  bool _useFlutterLogger = true;

  // Historique des logs en mémoire (limité à 1000 entrées par défaut)
  final List<LogEntry> _logHistory = [];
  static const int _maxLogEntries = 1000;

  // Accesseurs
  LogLevel get minLevel => _minLevel;
  List<LogEntry> get logHistory => List.unmodifiable(_logHistory);

  // Configuration du logger
  void configure({
    LogLevel? minLevel,
    bool? printToConsole,
    bool? storeInMemory,
    bool? useFlutterLogger,
  }) {
    _minLevel = minLevel ?? _minLevel;
    _printToConsole = printToConsole ?? _printToConsole;
    _storeInMemory = storeInMemory ?? _storeInMemory;
    _useFlutterLogger = useFlutterLogger ?? _useFlutterLogger;
  }

  // Méthodes de journalisation par niveau
  void debug(
    String message, {
    String tag = 'APP',
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  void info(
    String message, {
    String tag = 'APP',
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  void warning(
    String message, {
    String tag = 'APP',
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      data: data,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    String tag = 'APP',
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  void critical(
    String message, {
    String tag = 'APP',
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      data: data,
      stackTrace: stackTrace,
    );
  }

  // Méthode principale de journalisation
  void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? data,
    StackTrace? stackTrace,
  }) {
    // Ignorer les logs sous le niveau minimum
    if (level.index < _minLevel.index) {
      return;
    }

    final logEntry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      data: data,
      stackTrace: stackTrace,
    );

    // Stocker en mémoire si activé
    if (_storeInMemory) {
      _addToHistory(logEntry);
    }

    // Afficher dans la console si activé
    if (_printToConsole) {
      _printLog(logEntry);
    }
  }

  // Ajoute un log à l'historique en mémoire
  void _addToHistory(LogEntry logEntry) {
    _logHistory.add(logEntry);

    // Limiter la taille de l'historique
    if (_logHistory.length > _maxLogEntries) {
      _logHistory.removeAt(0); // Supprimer le plus ancien
    }
  }

  // Affiche le log dans la console
  void _printLog(LogEntry logEntry) {
    final logString = logEntry.toString();

    if (_useFlutterLogger) {
      switch (logEntry.level) {
        case LogLevel.debug:
        case LogLevel.info:
          developer.log(
            logString,
            name: logEntry.tag,
            time: logEntry.timestamp,
          );
          break;
        case LogLevel.warning:
          developer.log(
            logString,
            name: logEntry.tag,
            time: logEntry.timestamp,
            level: 900, // Niveau personnalisé pour warning
          );
          break;
        case LogLevel.error:
        case LogLevel.critical:
          developer.log(
            logString,
            name: logEntry.tag,
            time: logEntry.timestamp,
            level: 1000, // Niveau d'erreur
            error: logEntry.data,
            stackTrace: logEntry.stackTrace,
          );
          break;
      }
    } else {
      // Couleurs pour la console (ANSI escape codes)
      final String reset = '\x1B[0m';
      final String color = switch (logEntry.level) {
        LogLevel.debug => '\x1B[37m', // Blanc
        LogLevel.info => '\x1B[32m', // Vert
        LogLevel.warning => '\x1B[33m', // Jaune
        LogLevel.error => '\x1B[31m', // Rouge
        LogLevel.critical => '\x1B[35m', // Magenta
      };

      debug('$color$logString$reset');

      if (logEntry.stackTrace != null) {
        debug('$color${logEntry.stackTrace}$reset');
      }
    }
  }

  // Récupérer les logs filtrés
  List<LogEntry> getFilteredLogs({
    LogLevel? minLevel,
    LogLevel? maxLevel,
    String? tag,
    DateTime? startTime,
    DateTime? endTime,
    String? containsText,
  }) {
    return _logHistory.where((log) {
      // Filtrer par niveau
      if (minLevel != null && log.level.index < minLevel.index) return false;
      if (maxLevel != null && log.level.index > maxLevel.index) return false;

      // Filtrer par tag
      if (tag != null && log.tag != tag) return false;

      // Filtrer par timestamp
      if (startTime != null && log.timestamp.isBefore(startTime)) return false;
      if (endTime != null && log.timestamp.isAfter(endTime)) return false;

      // Filtrer par texte
      if (containsText != null &&
          !log.message.toLowerCase().contains(containsText.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  // Effacer l'historique des logs
  void clearHistory() {
    _logHistory.clear();
  }

  // Exporter les logs au format JSON
  String exportLogsAsJson() {
    final logList = _logHistory.map((log) => log.toMap()).toList();
    return logList.toString();
  }
}
