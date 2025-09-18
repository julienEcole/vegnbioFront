import 'package:flutter/material.dart';

class AppIcon {
  // Métadonnées de l'application
  static const String appName = "Veg'N Bio";
  static const String appDescription = "Application Veg'N Bio pour la restauration bio et végétarienne";
  static const String appVersion = "1.0.0";
  
  // Couleurs de l'icône
  static const Color primaryColor = Color(0xFF4CAF50); // Vert principal
  static const Color accentColor = Color(0xFF81C784);  // Vert clair
  static const Color backgroundColor = Color(0xFFFFFFFF); // Blanc
  
  // Configuration de l'icône pour différentes plateformes
  static const Map<String, String> iconPaths = {
    'android': 'assets/icon/playstore.png',
    'ios': 'assets/icon/appstore.png',
    'web': 'assets/icon/web.jpg',
    'favicon': 'assets/icon/playstore.png',
  };
  
  // Configuration des couleurs pour le thème de l'icône
  static const Map<String, Color> iconColors = {
    'primary': primaryColor,
    'accent': accentColor,
    'background': backgroundColor,
    'theme': primaryColor,
  };
  
  // Métadonnées pour le manifeste web
  static const Map<String, String> webManifest = {
    'name': appName,
    'short_name': 'VegnBio',
    'description': appDescription,
    'background_color': '#4CAF50',
    'theme_color': '#4CAF50',
    'display': 'standalone',
    'orientation': 'portrait-primary',
  };
}
