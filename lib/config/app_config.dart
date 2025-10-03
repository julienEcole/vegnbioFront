import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Métadonnées de l'application
  static const String appName = "Veg'N Bio";
  static const String appDescription = "Application Veg'N Bio pour la restauration bio et végétarienne";
  static const String appVersion = "1.0.0";
  static const String appBuildNumber = "1";
  
  // Configuration des icônes
  static const String iconPath = "assets/icon/playstore.png";
  static const String iconPathAndroid = "assets/icon/playstore.png";
  static const String iconPathIOS = "assets/icon/appstore.png";
  static const String iconPathWeb = "assets/icon/web.jpg";
  static const String stripePublicKey = "pk_test_51RlyHn2YwVRe9o01EpfpyAFyRj7dKZIQnL2Kqa4yYBe2ysoqGD61MOqiE5zC8K6Bts7VGMMxUF2e3tRCJjbI0k1B00MtSYa7MB";
  
  // Couleurs de l'application
  static const String primaryColorHex = "#4CAF50";
  static const String accentColorHex = "#81C784";
  static const String backgroundColorHex = "#FFFFFF";
  static const String themeColorHex = "#4CAF50";
  
  // Configuration de l'API (depuis les variables d'environnement)
  static String get apiBaseUrl {
    // Essayer d'abord les variables d'environnement système (pour la production)
    const apiUrl = String.fromEnvironment('API_BASE_URL');
    if (apiUrl.isNotEmpty) return apiUrl;
    
    // Sinon utiliser dotenv (pour le développement local)
    return dotenv.env['API_BASE_URL'] ?? "http://127.0.0.1:3001/api";
  }
  static const String apiVersion = "v1";
  
  // Configuration Stripe (depuis les variables d'environnement)
  static String get stripePublicKey {
    // Essayer d'abord les variables d'environnement système (pour la production)
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (stripeKey.isNotEmpty) return stripeKey;
    
    // Sinon utiliser dotenv (pour le développement local)
    return dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
  }
  
  // Configuration de l'environnement
  static String get environment {
    // Essayer d'abord les variables d'environnement système (pour la production)
    const env = String.fromEnvironment('ENVIRONMENT');
    if (env.isNotEmpty) return env;
    
    // Sinon utiliser dotenv (pour le développement local)
    return dotenv.env['ENVIRONMENT'] ?? "development";
  }
  
  // Configuration des routes
  static const String homeRoute = "/";
  static const String menusRoute = "/menus";
  static const String restaurantsRoute = "/restaurants";
  static const String profileRoute = "/profil";
  static const String dashboardRoute = "/dashboard";
  static const String cartRoute = "/panier";
  
  // Configuration des permissions
  static const List<String> adminRoles = ["admin"];
  static const List<String> restaurateurRoles = ["restaurateur", "admin"];
  static const List<String> fournisseurRoles = ["fournisseur", "admin"];
  static const List<String> clientRoles = ["client", "restaurateur", "fournisseur", "admin"];
  
  // Méthode pour initialiser les variables d'environnement
  static Future<void> loadEnv() async {
    // Vérifier si nous sommes en production (variables d'environnement système disponibles)
    const apiUrl = String.fromEnvironment('API_BASE_URL');
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    const env = String.fromEnvironment('ENVIRONMENT');
    
    if (apiUrl.isNotEmpty || stripeKey.isNotEmpty || env.isNotEmpty) {
      // Production : utiliser les variables d'environnement système
      print('✅ [AppConfig] Mode production - utilisation des variables d\'environnement système');
      print('🔗 [AppConfig] API Base URL: $apiBaseUrl');
      print('🔑 [AppConfig] Stripe Public Key: ${stripePublicKey.isNotEmpty ? "Configuré" : "Non configuré"}');
      print('🌍 [AppConfig] Environment: $environment');
      return;
    }
    
    // Développement local : essayer de charger le fichier .env
    try {
      await dotenv.load(fileName: ".env");
      print('✅ [AppConfig] Mode développement - variables d\'environnement chargées depuis .env');
      print('🔗 [AppConfig] API Base URL: $apiBaseUrl');
      print('🔑 [AppConfig] Stripe Public Key: ${stripePublicKey.isNotEmpty ? "Configuré" : "Non configuré"}');
      print('🌍 [AppConfig] Environment: $environment');
      
      // Debug: afficher toutes les variables chargées
      print('📋 [AppConfig] Toutes les variables d\'environnement:');
      dotenv.env.forEach((key, value) {
        print('   $key = $value');
      });
    } catch (e) {
      print('⚠️  [AppConfig] Fichier .env non trouvé, utilisation des valeurs par défaut');
      print('🔗 [AppConfig] API Base URL par défaut: $apiBaseUrl');
      print('🔑 [AppConfig] Stripe Public Key par défaut: ${stripePublicKey.isNotEmpty ? "Configuré" : "Non configuré"}');
      print('🌍 [AppConfig] Environment par défaut: $environment');
    }
  }
}
