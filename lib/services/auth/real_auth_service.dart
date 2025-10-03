import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

/// Service d'authentification réel qui communique avec l'API backend
class RealAuthService {
  static final RealAuthService _instance = RealAuthService._internal();
  factory RealAuthService() => _instance;
  RealAuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Configuration de l'API
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  String? _token;
  Map<String, dynamic>? _userData;
  bool _isLoggedIn = false;

  /// Initialiser le service en vérifiant le token stocké
  Future<void> initialize() async {
    print('🔐 [RealAuthService] Initialisation...');
    print('🌐 [RealAuthService] URL de base: $baseUrl');
    
    try {
      // Test de connectivité réseau
      await _testConnectivity();
      
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (_token != null && _isLoggedIn) {
        // Vérifier si le token est encore valide (les données utilisateur sont récupérées automatiquement)
        final isValid = await verifyToken();
        if (isValid) {
          print('✅ [RealAuthService] Token valide, utilisateur connecté');
        } else {
          print('❌ [RealAuthService] Token invalide, déconnexion');
          await logout();
        }
      } else {
        print('🌐 [RealAuthService] Aucun token trouvé, utilisateur non connecté');
        _isLoggedIn = false;
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur d\'initialisation: $e');
      _isLoggedIn = false;
    }
  }

  /// Tester la connectivité avec le backend
  Future<void> _testConnectivity() async {
    try {
      print('🔍 [RealAuthService] Test de connectivité...');
      // Utiliser l'URL de base configurée au lieu de l'URL codée en dur
      final healthUrl = baseUrl.replaceAll('/api', '/health');
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('✅ [RealAuthService] Backend accessible (${response.statusCode})');
      print('📄 [RealAuthService] Réponse santé: ${response.body}');
    } catch (e) {
      print('⚠️ [RealAuthService] Test de connectivité échoué: $e');
      print('🔧 [RealAuthService] Vérifiez que le backend est démarré sur $baseUrl');
    }
  }

  /// Obtenir les headers avec le token d'authentification
  Map<String, String> get authHeaders {
    final authHeaders = Map<String, String>.from(headers);
    if (_token != null) {
      authHeaders['Authorization'] = 'Bearer $_token';
    }
    return authHeaders;
  }

  /// Connexion avec email et mot de passe
  Future<bool> login(String email, String password) async {
    print('🔐 [RealAuthService] Tentative de connexion: $email');
    print('🌐 [RealAuthService] URL de connexion: $baseUrl/auth/login');
    
    try {
      final requestBody = json.encode({
        'email': email,
        'password': password,
      });
      
      print('📤 [RealAuthService] Corps de la requête: $requestBody');
      print('📤 [RealAuthService] Headers: $headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('📡 [RealAuthService] Statut de réponse: ${response.statusCode}');
      print('📄 [RealAuthService] Corps de réponse: ${response.body}');
      print('📄 [RealAuthService] Headers de réponse: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          _token = data['token'];
          _isLoggedIn = true;
          
          // Sauvegarder le token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setBool(_isLoggedInKey, true);
          
          // Récupérer les données utilisateur
          await _loadUserData();
          
          print('✅ [RealAuthService] Connexion réussie');
          return true;
        } else {
          print('❌ [RealAuthService] Échec de la connexion: ${data['message']}');
          return false;
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ [RealAuthService] Erreur HTTP: ${errorData['message']}');
        } catch (e) {
          print('❌ [RealAuthService] Erreur HTTP ${response.statusCode}: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur de connexion détaillée: $e');
      print('❌ [RealAuthService] Type d\'erreur: ${e.runtimeType}');
      
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('SocketException')) {
        print('🌐 [RealAuthService] Problème de connectivité réseau');
        print('🔧 [RealAuthService] Vérifiez que le backend est accessible sur $baseUrl');
      }
      
      return false;
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String nameRole,
  }) async {
    print('📝 [RealAuthService] Tentative d\'inscription: $email');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: json.encode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motDePasse': motDePasse,
          'nameRole': nameRole,
        }),
      );

      print('📡 [RealAuthService] Statut d\'inscription: ${response.statusCode}');
      print('📄 [RealAuthService] Réponse inscription: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          _token = data['token'];
          _isLoggedIn = true;
          
          // Sauvegarder le token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setBool(_isLoggedInKey, true);
          
          // Récupérer les données utilisateur
          await _loadUserData();
          
          print('✅ [RealAuthService] Inscription réussie');
          return true;
        } else {
          print('❌ [RealAuthService] Échec de l\'inscription: ${data['message']}');
          return false;
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ [RealAuthService] Erreur inscription: ${errorData['message']}');
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur d\'inscription: $e');
      return false;
    }
  }

  /// Vérifier si le token est valide
  Future<bool> verifyToken() async {
    if (_token == null) return false;
    
    try {
      print('🔍 [RealAuthService] Vérification du token...');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [RealAuthService] Token valide');
        
        if (data['valid'] == true && data['user'] != null) {
          // Utiliser les données utilisateur retournées par la vérification
          _userData = data['user'];
          
          // Sauvegarder les données utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, json.encode(_userData));
          
          print('✅ [RealAuthService] Données utilisateur mises à jour');
        }
        
        return data['valid'] == true;
      } else {
        print('❌ [RealAuthService] Token invalide');
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur vérification token: $e');
      return false;
    }
  }

  /// Charger les données utilisateur depuis l'API
  Future<void> _loadUserData() async {
    if (_token == null) return;
    
    try {
      print('👤 [RealAuthService] Chargement des données utilisateur...');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          _userData = data['user'];
          
          // Sauvegarder les données utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, json.encode(_userData));
          
          print('✅ [RealAuthService] Données utilisateur chargées');
        }
      } else {
        print('❌ [RealAuthService] Erreur chargement profil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur chargement profil: $e');
    }
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  Future<bool> hasRole(String role) async {
    if (_token == null) return false;
    
    try {
      print('🔍 [RealAuthService] Vérification du rôle: $role');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/$role'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [RealAuthService] Rôle $role vérifié: ${data['success']}');
        return data['success'] == true;
      } else {
        print('❌ [RealAuthService] Rôle $role non autorisé');
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthService] Erreur vérification rôle: $e');
      return false;
    }
  }

  /// Charger le profil complet de l'utilisateur
  Future<bool> loadUserProfile() async {
    if (_token == null) return false;
    
    try {
      print('👤 [RealAuthService] Chargement du profil utilisateur...');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: authHeaders,
      );

      print('📡 [RealAuthService] Statut profil: ${response.statusCode}');
      print('📄 [RealAuthService] Réponse profil: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          _userData = data['user'];
          
          // Sauvegarder les données utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, json.encode(_userData));
          
          print('✅ [RealAuthService] Profil utilisateur chargé avec succès');
          return true;
        }
      }
      
      print('❌ [RealAuthService] Échec du chargement du profil');
      return false;
    } catch (e) {
      print('❌ [RealAuthService] Erreur chargement profil: $e');
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    print('🚪 [RealAuthService] Déconnexion...');
    
    _token = null;
    _userData = null;
    _isLoggedIn = false;
    
    // Supprimer des préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_isLoggedInKey);
    
    print('✅ [RealAuthService] Déconnexion réussie');
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    String? email,
  }) async {
    if (_token == null) return false;
    
    print('📝 [RealAuthService] Mise à jour du profil...');
    
    try {
      final updateData = {
        'nom': nom,
        'prenom': prenom,
      };
      
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: authHeaders,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Mettre à jour les données utilisateur avec la réponse
          _userData = data['user'];
          
          // Sauvegarder les nouvelles données
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, json.encode(_userData));
          
          print('✅ [RealAuthService] Profil mis à jour avec succès');
          return true;
        }
      }
      
      print('❌ [RealAuthService] Échec de la mise à jour du profil');
      return false;
    } catch (e) {
      print('❌ [RealAuthService] Erreur mise à jour profil: $e');
      return false;
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String newPassword) async {
    if (_token == null) return false;
    
    print('🔐 [RealAuthService] Changement du mot de passe...');
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/password'),
        headers: authHeaders,
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      print('📡 [RealAuthService] Statut changement mot de passe: ${response.statusCode}');
      print('📄 [RealAuthService] Réponse changement mot de passe: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ [RealAuthService] Mot de passe modifié avec succès');
          return true;
        }
      }
      
      print('❌ [RealAuthService] Échec du changement de mot de passe');
      return false;
    } catch (e) {
      print('❌ [RealAuthService] Erreur changement mot de passe: $e');
      return false;
    }
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  String? get userRole => _userData?['role'];
  String? get token => _token;
}
