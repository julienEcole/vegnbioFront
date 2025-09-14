import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3001/api/auth';
  
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Clés pour le stockage local
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  /// Connexion utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('AuthService - Tentative de connexion pour: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('AuthService - Statut HTTP connexion: ${response.statusCode}');
      print('AuthService - Corps de la réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        
        print('AuthService - Token reçu: $token');
        
        if (token != null) {
          // Pour la connexion, on passe l'email utilisé pour la connexion
          return await _processToken(token, 'login', email);
        } else {
          return {
            'success': false,
            'message': 'Token manquant dans la réponse',
          };
        }
      } else {
        // Traiter les erreurs (401, 400, etc.)
        final errorData = json.decode(response.body);
        print('AuthService - Erreur de connexion: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      print('AuthService - Erreur lors de la connexion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Enregistrement utilisateur
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String nameRole = 'client',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motDePasse': motDePasse,
          'nameRole': nameRole,
        }),
      );

      print('AuthService - Statut HTTP inscription: ${response.statusCode}');
      print('AuthService - Corps de la réponse: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        
        print('AuthService - Réponse API inscription: $data');
        print('AuthService - Token reçu: $token');
        
        if (token != null) {
          return await _processToken(token, 'register', email);
        }
        
        // Si pas de token, retourner quand même un succès
        return {
          'success': true,
          'message': 'Inscription réussie !',
          'user': data,
        };
      }
      
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Erreur d\'inscription',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur d\'inscription: $e',
      };
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    print('🔑 [AuthService] ===== isLoggedIn() =====');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final result = token != null;
    print('🔑 [AuthService] Token: ${token != null ? "PRÉSENT" : "ABSENT"}');
    print('🔑 [AuthService] Résultat isLoggedIn: $result');
    return result;
  }

  /// Obtenir le token actuel
  Future<String?> getToken() async {
    print('🔑 [AuthService] ===== getToken() =====');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('🔑 [AuthService] Token récupéré: ${token != null ? "OUI" : "NON"}');
    return token;
  }

  /// Obtenir le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Obtenir l'ID de l'utilisateur
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString(_userIdKey);
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  /// Obtenir l'email de l'utilisateur
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  Future<bool> hasRole(String role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  /// Vérifier si l'utilisateur a l'un des rôles spécifiés
  Future<bool> hasAnyRole(List<String> roles) async {
    final userRole = await getUserRole();
    return userRole != null && roles.contains(userRole);
  }

  /// Récupérer le profil complet de l'utilisateur depuis l'API
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ [AuthService] Pas de token pour récupérer le profil');
        return null;
      }

      print('🔍 [AuthService] Récupération du profil avec token: ${token.substring(0, 50)}...');
      
      // Test de connectivité d'abord
      try {
        final testResponse = await http.get(
          Uri.parse('http://localhost:3001/'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        print('✅ [AuthService] Backend accessible (${testResponse.statusCode})');
      } catch (testError) {
        print('❌ [AuthService] Backend non accessible: $testError');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 [AuthService] Statut de réponse: ${response.statusCode}');
      print('📄 [AuthService] Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          print('✅ [AuthService] Profil utilisateur récupéré avec succès');
          print('✅ [AuthService] Données utilisateur: ${data['user']}');
          return data['user'];
        } else {
          print('❌ [AuthService] Réponse API indique un échec: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        print('🔐 [AuthService] Token invalide ou expiré (401)');
        await logout(); // Nettoyer le token invalide
      } else {
        print('❌ [AuthService] Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la récupération du profil: $e');
      // Si erreur réseau, ne pas invalider le token
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        print('🌐 [AuthService] Erreur réseau détectée - Token conservé');
        return null;
      }
      rethrow;
    }
    return null;
  }

  /// Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  /// Traiter un token et retourner la réponse d'authentification
  Future<Map<String, dynamic>> _processToken(String token, String operation, [String? email]) async {
    try {
      // Décoder le token pour extraire les informations utilisateur
      final tokenParts = token.split('.');
      if (tokenParts.length == 2) {
        // Corriger le décodage base64 en ajoutant le padding manquant
        String base64Payload = tokenParts[0];
        while (base64Payload.length % 4 != 0) {
          base64Payload += '=';
        }
        
        final payload = json.decode(
          String.fromCharCodes(base64.decode(base64Payload))
        );
        
        print('AuthService - Payload du token décodé: $payload');
        
        // Sauvegarder le token et les informations utilisateur
        await _saveAuthData(token, payload['role'], payload['id'], email);
        
        return {
          'success': true,
          'message': operation == 'login' 
            ? 'Connexion réussie ! Bienvenue ${payload['role']}'
            : 'Inscription réussie ! Bienvenue ${payload['role']}',
          'token': token,
          'role': payload['role'],
          'userId': payload['id'],
          'email': email,
        };
      }
    } catch (e) {
      print('Erreur décodage token $operation: $e');
    }
    
    // Fallback : utiliser des valeurs par défaut
    await _saveAuthData(token, 'client', 0);
    return {
      'success': true,
      'message': operation == 'login' 
        ? 'Connexion réussie ! Bienvenue client'
        : 'Inscription réussie ! Bienvenue client',
      'token': token,
      'role': 'client',
      'userId': 0,
    };
  }

  /// Sauvegarder les données d'authentification
  Future<void> _saveAuthData(String token, String role, int userId, [String? email]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, userId.toString());
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }
  }

  /// Obtenir les headers d'authentification pour les requêtes API
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Vérifier la validité d'un token (validation locale)
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
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
          await logout(); // Supprimer le token expiré
          return false;
        }
      }

      print('✅ Token valide détecté');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la validation du token: $e');
      await logout(); // Supprimer le token invalide
      return false;
    }
  }

  /// Vérifier la validité du token avec le backend (pour les requêtes importantes)
  Future<bool> verifyTokenWithBackend() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur lors de la vérification backend du token: $e');
      return false;
    }
  }

  /// Changer le mot de passe de l'utilisateur
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      print('AuthService - Tentative de changement de mot de passe');
      
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      print('AuthService - Statut HTTP changement mot de passe: ${response.statusCode}');
      print('AuthService - Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe changé avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors du changement de mot de passe',
        };
      }
    } catch (e) {
      print('AuthService - Erreur lors du changement de mot de passe: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
