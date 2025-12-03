import 'package:intl/intl.dart';

/// Professional logger utility for OncoNutri+ app
/// Provides clean, structured logging similar to production log systems
class AppLogger {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss,SSS');
  
  /// Log levels
  static const String _info = 'INFO';
  static const String _error = 'ERROR';
  static const String _debug = 'DEBUG';
  
  /// Log an INFO level message
  static void info(String module, String message) {
    _log(_info, module, message);
  }
  
  /// Log an ERROR level message
  static void error(String module, String message) {
    _log(_error, module, message);
  }
  
  /// Log a DEBUG level message
  static void debug(String module, String message) {
    _log(_debug, module, message);
  }
  
  /// Core logging function
  static void _log(String level, String module, String message) {
    final timestamp = _dateFormat.format(DateTime.now());
    final logEntry = '$timestamp - $level - $module - $message';
    
    // Print to console
    // ignore: avoid_print
    print(logEntry);
  }
}

