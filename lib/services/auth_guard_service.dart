import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_validator_service.dart';

/// Service de garde d'authentification pour vérifier les tokens avant l'accès aux pages
class AuthGuardService {
  static const String baseUrl = 'http://localhost:3001/api/auth';
  
  // Singleton
  static final AuthGuardService _instance = AuthGuardService._internal();
  factory AuthGuardService() => _instance;
  AuthGuardService._internal();

  /// Vérifier si l'utilisateur a le rôle requis
  Future<bool> hasRequiredRole(String requiredRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      return userRole == requiredRole;
    } catch (e) {
      print('❌ Erreur lors de la vérification du rôle: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur a l'un des rôles requis
  Future<bool> hasAnyRequiredRole(List<String> requiredRoles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      return requiredRoles.contains(userRole);
    } catch (e) {
      print('❌ Erreur lors de la vérification des rôles: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur est admin
  Future<bool> isAdmin() async {
    return await hasRequiredRole('admin');
  }

  /// Vérifier si l'utilisateur est restaurateur
  Future<bool> isRestaurateur() async {
    return await hasRequiredRole('restaurateur');
  }

  /// Vérifier si l'utilisateur est fournisseur
  Future<bool> isFournisseur() async {
    return await hasRequiredRole('fournisseur');
  }

  /// Vérifier si l'utilisateur est client
  Future<bool> isClient() async {
    return await hasRequiredRole('client');
  }

  /// Vérifier si l'utilisateur a accès aux fonctionnalités d'administration
  Future<bool> hasAdminAccess() async {
    return await hasAnyRequiredRole(['admin', 'restaurateur']);
  }

  /// Vérifier si l'utilisateur a accès aux fonctionnalités de fournisseur
  Future<bool> hasFournisseurAccess() async {
    return await hasAnyRequiredRole(['admin', 'fournisseur']);
  }

  /// Vérifier le token et le rôle pour une page spécifique
  Future<AuthResult> checkAccess({
    required String pageType, // 'admin', 'restaurateur', 'fournisseur', 'client'
    bool requireAuth = true,
  }) async {
    try {
      // Si l'authentification n'est pas requise, autoriser l'accès
      if (!requireAuth) {
        return AuthResult(
          hasAccess: true,
          isValidToken: true,
          userRole: null,
          message: 'Accès public autorisé',
        );
      }

      // Vérifier la validité du token
      final tokenValidator = TokenValidatorService();
      final isValidToken = await tokenValidator.ensureTokenValid();
      
      if (!isValidToken) {
        return AuthResult(
          hasAccess: false,
          isValidToken: false,
          userRole: null,
          message: 'Token invalide ou expiré',
        );
      }

      // Récupérer le rôle de l'utilisateur
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      // Vérifier l'accès selon le type de page
      bool hasAccess = false;
      String message = '';

      switch (pageType.toLowerCase()) {
        case 'admin':
          hasAccess = await hasAdminAccess();
          message = hasAccess ? 'Accès admin autorisé' : 'Accès admin refusé';
          break;
        case 'restaurateur':
          hasAccess = await isRestaurateur() || await isAdmin();
          message = hasAccess ? 'Accès restaurateur autorisé' : 'Accès restaurateur refusé';
          break;
        case 'fournisseur':
          hasAccess = await hasFournisseurAccess();
          message = hasAccess ? 'Accès fournisseur autorisé' : 'Accès fournisseur refusé';
          break;
        case 'client':
          hasAccess = await isClient() || await isAdmin();
          message = hasAccess ? 'Accès client autorisé' : 'Accès client refusé';
          break;
        default:
          hasAccess = true; // Pour les pages publiques
          message = 'Accès autorisé';
      }

      return AuthResult(
        hasAccess: hasAccess,
        isValidToken: isValidToken,
        userRole: userRole,
        message: message,
      );
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'accès: $e');
      return AuthResult(
        hasAccess: false,
        isValidToken: false,
        userRole: null,
        message: 'Erreur lors de la vérification d\'accès: $e',
      );
    }
  }

  /// Afficher un popup temporaire pour un token invalide
  void showTokenInvalidPopup(BuildContext context, {String? customMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                customMessage ?? 'Token invalide. Redirection vers la page de connexion...',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Rediriger vers la page de connexion
  void redirectToLogin(BuildContext context) {
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        context.push('/profil');
      }
    });
  }

  /// Nettoyer les données d'authentification
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      print('🗑️ Données d\'authentification supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression des données d\'authentification: $e');
    }
  }
}

/// Résultat de la vérification d'authentification
class AuthResult {
  final bool hasAccess;
  final bool isValidToken;
  final String? userRole;
  final String message;

  AuthResult({
    required this.hasAccess,
    required this.isValidToken,
    this.userRole,
    required this.message,
  });

  @override
  String toString() {
    return 'AuthResult(hasAccess: $hasAccess, isValidToken: $isValidToken, userRole: $userRole, message: $message)';
  }
}
