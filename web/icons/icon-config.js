// Configuration des icônes pour l'application Veg'N Bio
const iconConfig = {
  appName: "Veg'N Bio",
  appDescription: "Application Veg'N Bio pour la restauration bio et végétarienne",
  appVersion: "1.0.0",
  
  // Chemins des icônes
  icons: {
    favicon: "favicon.png",
    faviconIco: "favicon.ico",
    appleTouch: "Icon-192.png",
    android: "Icon-192.png",
    web: "Icon-512.png"
  },
  
  // Couleurs de l'application
  colors: {
    primary: "#4CAF50",
    accent: "#81C784",
    background: "#FFFFFF",
    theme: "#4CAF50"
  },
  
  // Métadonnées pour le manifeste
  manifest: {
    name: "Veg'N Bio",
    short_name: "VegnBio",
    description: "Application Veg'N Bio pour la restauration bio et végétarienne",
    start_url: ".",
    display: "standalone",
    background_color: "#4CAF50",
    theme_color: "#4CAF50",
    orientation: "portrait-primary",
    prefer_related_applications: false
  }
};

// Export pour utilisation dans d'autres fichiers
if (typeof module !== 'undefined' && module.exports) {
  module.exports = iconConfig;
} else {
  window.iconConfig = iconConfig;
}
