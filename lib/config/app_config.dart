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
  
  // Couleurs de l'application
  static const String primaryColorHex = "#4CAF50";
  static const String accentColorHex = "#81C784";
  static const String backgroundColorHex = "#FFFFFF";
  static const String themeColorHex = "#4CAF50";
  
  // Configuration de l'API (depuis les variables d'environnement)
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? "http://127.0.0.1:3001/api";
  static const String apiVersion = "v1";
  
  // Configuration Stripe (depuis les variables d'environnement)
  static String get stripePublicKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
  
  // Configuration de l'environnement
  static String get environment => dotenv.env['ENVIRONMENT'] ?? "development";
  
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
    try {
      await dotenv.load(fileName: ".env");
      print('✅ [AppConfig] Variables d\'environnement chargées');
      print('🔗 [AppConfig] API Base URL: $apiBaseUrl');
      print('🔑 [AppConfig] Stripe Public Key: ${stripePublicKey.isNotEmpty ? "Configuré" : "Non configuré"}');
      print('🌍 [AppConfig] Environment: $environment');
      
      // Debug: afficher toutes les variables chargées
      print('📋 [AppConfig] Toutes les variables d\'environnement:');
      dotenv.env.forEach((key, value) {
        print('   $key = $value');
      });
    } catch (e) {
      print('❌ [AppConfig] Erreur lors du chargement des variables d\'environnement: $e');
      print('⚠️  [AppConfig] Utilisation des valeurs par défaut');
      print('🔗 [AppConfig] API Base URL par défaut: $apiBaseUrl');
    }
  }
}
