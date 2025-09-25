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
  
  // Configuration de l'API
  static const String apiBaseUrl = "http://127.0.0.1:3001/api";
  static const String apiVersion = "v1";
  
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
}
