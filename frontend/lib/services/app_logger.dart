class AppLogger {
  static void info(String message) {
    print('[INFO] $message');
  }
  
  static void error(String message, [Object? error]) {
    print('[ERROR] $message${error != null ? ': $error' : ''}');
  }
  
  static void warning(String message) {
    print('[WARNING] $message');
  }
  
  static void debug(String message) {
    print('[DEBUG] $message');
  }
}

