import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenValidatorService {
  static const String baseUrl = 'http://localhost:3001/api/auth';
  
  // Singleton
  static final TokenValidatorService _instance = TokenValidatorService._internal();
  factory TokenValidatorService() => _instance;
  TokenValidatorService._internal();

  /// Vérifier si le token actuel est valide (validation locale)
  Future<bool> isCurrentTokenValid() async {
    print('🔍 [TokenValidatorService] ===== isCurrentTokenValid() =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      print('🔍 [TokenValidatorService] Token présent: ${token != null}');
      if (token == null) return false;

      // Vérifier le format du token personnalisé
      final tokenParts = token.split('.');
      if (tokenParts.length != 2) return false;

      // Décoder le payload pour vérifier la validité
      String base64Payload = tokenParts[0];
      while (base64Payload.length % 4 != 0) {
        base64Payload += '=';
      }
      
      final payload = json.decode(
        String.fromCharCodes(base64.decode(base64Payload))
      );

      // Vérifier si le token n'est pas expiré (si timestamp présent)
      if (payload['ts'] != null) {
        final tokenTimestamp = payload['ts'] as int;
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        // Token valide pendant 24h (86400000 ms)
        if (currentTimestamp - tokenTimestamp > 86400000) {
          print('🗑️ Token expiré détecté');
          return false;
        }
      }

      print('✅ Token valide détecté');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la validation du token: $e');
      return false;
    }
  }

  /// Vérifier et nettoyer le token si nécessaire
  Future<bool> validateAndCleanToken() async {
    final isValid = await isCurrentTokenValid();
    
    if (!isValid) {
      // Token invalide, le supprimer
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      print('🗑️ Token invalide supprimé');
    }
    
    return isValid;
  }

  /// Vérifier la validité du token avant une action importante
  Future<bool> ensureTokenValid() async {
    print('🔍 [TokenValidatorService] ===== ensureTokenValid() =====');
    final isValid = await validateAndCleanToken();
    
    print('🔍 [TokenValidatorService] Token valide après vérification: $isValid');
    if (!isValid) {
      print('⚠️ Token invalide détecté, action refusée');
    }
    
    return isValid;
  }
}
