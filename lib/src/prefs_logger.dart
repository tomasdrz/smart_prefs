/// Log levels for preference operations.
enum PrefsLogLevel {
  /// Debug messages for development.
  debug,

  /// Informational messages about normal operations.
  info,

  /// Warning messages about potential issues.
  warning,

  /// Error messages for failures.
  error,
}

/// Callback function type for logging preference operations.
///
/// [level] indicates the severity of the log message.
/// [message] contains the log message text.
///
/// Example:
/// ```dart
/// void myLogger(PrefsLogLevel level, String message) {
///   print('[${level.name.toUpperCase()}] $message');
/// }
/// ```
typedef PrefsLogger = void Function(PrefsLogLevel level, String message);

/// Default logger that prints to console.
void defaultPrefsLogger(PrefsLogLevel level, String message) {
  final levelStr = level.name.toUpperCase().padRight(7);
  print('[$levelStr] Prefs: $message');
}
