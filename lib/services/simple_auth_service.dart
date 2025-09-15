import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'authentification simplifié avec singleton
/// Évite les conflits et les blocages
class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDataKey = 'user_data';

  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;

  /// Initialiser le service
  Future<void> initialize() async {
    print('🔐 [SimpleAuthService] Initialisation...');
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (_isLoggedIn) {
        final userDataString = prefs.getString(_userDataKey);
        if (userDataString != null) {
          // Simuler des données utilisateur pour le test
          _userData = {
            'id': 1,
            'email': 'test@example.com',
            'nom': 'Test',
            'prenom': 'User',
            'role': 'client',
          };
        }
      }
      
      print('🔐 [SimpleAuthService] Initialisé - Connecté: $_isLoggedIn');
    } catch (e) {
      print('❌ [SimpleAuthService] Erreur d\'initialisation: $e');
      _isLoggedIn = false;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _isLoggedIn;

  /// Obtenir les données utilisateur
  Map<String, dynamic>? get userData => _userData;

  /// Obtenir le rôle de l'utilisateur
  String? get userRole => _userData?['role'];

  /// Connexion simplifiée (simulation)
  Future<bool> login(String email, String password) async {
    print('🔐 [SimpleAuthService] Tentative de connexion: $email');
    
    // Simulation d'une connexion réussie
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      _userData = {
        'id': 1,
        'email': email,
        'nom': 'Test',
        'prenom': 'User',
        'role': 'client',
      };
      
      // Sauvegarder dans les préférences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userDataKey, '{"id":1,"email":"$email","nom":"Test","prenom":"User","role":"client"}');
      
      print('✅ [SimpleAuthService] Connexion réussie');
      return true;
    }
    
    print('❌ [SimpleAuthService] Échec de la connexion');
    return false;
  }

  /// Inscription simplifiée (simulation)
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String nameRole,
  }) async {
    print('📝 [SimpleAuthService] Tentative d\'inscription: $email');
    
    // Simulation d'une inscription réussie
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isNotEmpty && motDePasse.isNotEmpty) {
      _isLoggedIn = true;
      _userData = {
        'id': 2,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'role': nameRole,
      };
      
      // Sauvegarder dans les préférences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userDataKey, '{"id":2,"email":"$email","nom":"$nom","prenom":"$prenom","role":"$nameRole"}');
      
      print('✅ [SimpleAuthService] Inscription réussie');
      return true;
    }
    
    print('❌ [SimpleAuthService] Échec de l\'inscription');
    return false;
  }

  /// Déconnexion
  Future<void> logout() async {
    print('🚪 [SimpleAuthService] Déconnexion...');
    
    _isLoggedIn = false;
    _userData = null;
    
    // Supprimer des préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userDataKey);
    
    print('✅ [SimpleAuthService] Déconnexion réussie');
  }

  /// Mettre à jour le profil (simulation)
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    print('📝 [SimpleAuthService] Mise à jour du profil...');
    
    if (_userData != null) {
      _userData!['nom'] = nom;
      _userData!['prenom'] = prenom;
      if (telephone != null) {
        _userData!['telephone'] = telephone;
      }
      
      // Sauvegarder les modifications
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, '{"id":${_userData!['id']},"email":"${_userData!['email']}","nom":"$nom","prenom":"$prenom","role":"${_userData!['role']}","telephone":"$telephone"}');
      
      print('✅ [SimpleAuthService] Profil mis à jour');
      return true;
    }
    
    return false;
  }

  /// Changer le mot de passe (simulation)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    print('🔐 [SimpleAuthService] Changement du mot de passe...');
    
    // Simulation d'un changement réussi
    await Future.delayed(const Duration(seconds: 1));
    
    if (currentPassword.isNotEmpty && newPassword.isNotEmpty) {
      print('✅ [SimpleAuthService] Mot de passe changé');
      return true;
    }
    
    return false;
  }
}
