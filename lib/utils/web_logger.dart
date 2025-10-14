/// Utilitaire pour les logs qui apparaissent dans la console du navigateur
/// Utilise print() comme les providers existants
class WebLogger {
  static void log(String message) {
    // print(message);
  }
  
  static void error(String message) {
    // print('ERROR: $message');
  }
  
  static void warn(String message) {
    // print('WARN: $message');
  }
  
  static void info(String message) {
    // print('INFO: $message');
  }
  
  static void debug(String message) {
    // print('DEBUG: $message');
  }
  
  /// Log avec un style coloré dans la console
  static void logStyled(String message, {String color = '#2196F3'}) {
    // print(message);
  }
  
  /// Log avec un style coloré et une icône emoji
  static void logWithEmoji(String message, String emoji, {String color = '#2196F3'}) {
    // print('$emoji $message');
  }
}
