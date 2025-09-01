import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer la navigation et les redirections après connexion
class NavigationService {
  static const String _lastPageKey = 'last_visited_page';
  static const String _lastPageParamsKey = 'last_page_params';
  
  // Singleton
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Sauvegarder la page actuelle avant la redirection vers la connexion
  Future<void> saveCurrentPage(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLocation = GoRouterState.of(context).uri.path;
      final currentParams = GoRouterState.of(context).pathParameters;
      
      await prefs.setString(_lastPageKey, currentLocation);
      await prefs.setString(_lastPageParamsKey, currentParams.toString());
      
      print('📍 NavigationService: Page sauvegardée: $currentLocation');
    } catch (e) {
      print('❌ NavigationService: Erreur lors de la sauvegarde de la page: $e');
    }
  }

  /// Naviguer vers la page de connexion en sauvegardant la page actuelle
  Future<void> navigateToLogin(BuildContext context) async {
    await saveCurrentPage(context);
    
    if (context.mounted) {
      // Naviguer vers la page de profil/connexion
      context.go('/profil');
    }
  }

  /// Revenir à la page précédente après connexion réussie
  Future<void> returnToPreviousPage(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getString(_lastPageKey);
      
      if (lastPage != null && lastPage.isNotEmpty && lastPage != '/profil') {
        print('🔄 NavigationService: Retour à la page précédente: $lastPage');
        
        // Nettoyer les données sauvegardées
        await prefs.remove(_lastPageKey);
        await prefs.remove(_lastPageParamsKey);
        
        if (context.mounted) {
          context.go(lastPage);
        }
      } else {
        // Aller à la page d'accueil par défaut
        print('🏠 NavigationService: Redirection vers l\'accueil');
        if (context.mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      print('❌ NavigationService: Erreur lors du retour à la page précédente: $e');
      // En cas d'erreur, aller à l'accueil
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  /// Obtenir la page précédente sauvegardée
  Future<String?> getPreviousPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastPageKey);
    } catch (e) {
      print('❌ NavigationService: Erreur lors de la récupération de la page précédente: $e');
      return null;
    }
  }

  /// Nettoyer les données de navigation
  Future<void> clearNavigationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastPageKey);
      await prefs.remove(_lastPageParamsKey);
      print('🗑️ NavigationService: Données de navigation nettoyées');
    } catch (e) {
      print('❌ NavigationService: Erreur lors du nettoyage: $e');
    }
  }

  /// Vérifier si une page précédente est sauvegardée
  Future<bool> hasPreviousPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getString(_lastPageKey);
      return lastPage != null && lastPage.isNotEmpty && lastPage != '/profil';
    } catch (e) {
      return false;
    }
  }
}
