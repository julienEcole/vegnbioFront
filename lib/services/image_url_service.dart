import 'dart:convert';

class ImageUrlService {
  static const String _baseUrl = 'http://localhost:3001/api/images';

  /// Construit une URL d'image redimensionnée pour un restaurant
  /// 
  /// [imagePath] : Chemin de l'image (ex: "Bastille/exterieur.png")
  /// [width] : Largeur souhaitée (optionnel)
  /// [height] : Hauteur souhaitée (optionnel)
  /// [quality] : Qualité de l'image (1-100, défaut: 80)
  /// [format] : Format de sortie (jpeg, png, webp, défaut: jpeg)
  /// [fit] : Mode de redimensionnement (cover, contain, fill, inside, outside, défaut: cover)
  static String buildRestaurantImageUrl({
    required String imagePath,
    double? width,
    double? height,
    int quality = 80,
    String format = 'jpeg',
    String fit = 'cover',
  }) {
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    return _buildImageUrl(
      type: 'restaurants',
      path: imagePath,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: fit,
    );
  }

  /// Construit une URL d'image redimensionnée pour un menu
  /// 
  /// [imageName] : Nom de l'image (ex: "Menu Ete Fraicheur.png")
  /// [width] : Largeur souhaitée (optionnel)
  /// [height] : Hauteur souhaitée (optionnel)
  /// [quality] : Qualité de l'image (1-100, défaut: 80)
  /// [format] : Format de sortie (jpeg, png, webp, défaut: jpeg)
  /// [fit] : Mode de redimensionnement (cover, contain, fill, inside, outside, défaut: cover)
  static String buildMenuImageUrl({
    required String imageName,
    double? width,
    double? height,
    int quality = 80,
    String format = 'jpeg',
    String fit = 'cover',
  }) {
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      return imageName;
    }
    
    return _buildImageUrl(
      type: 'menus',
      path: imageName,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: fit,
    );
  }

  /// Construit une URL d'image redimensionnée générique
  static String _buildImageUrl({
    required String type,
    required String path,
    double? width,
    double? height,
    int quality = 80,
    String format = 'jpeg',
    String fit = 'cover',
  }) {
    final params = <String>[];

    if (width != null) params.add('w=${width.round()}');
    if (height != null) params.add('h=${height.round()}');
    if (quality != 80) params.add('q=$quality');
    if (format != 'jpeg') params.add('f=$format');
    if (fit != 'cover') params.add('fit=$fit');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    
    // Pour les restaurants, séparer le dossier et le nom de fichier
    if (type == 'restaurants' && path.contains('/')) {
      final parts = path.split('/');
      if (parts.length == 2) {
        final folder = parts[0]; // Le dossier (ex: "republique")
        final filename = parts[1]; // Le nom de fichier (ex: "Veg'N Bio République dehors.png")
        // Encoder seulement le nom de fichier, pas le dossier
        final encodedFilename = Uri.encodeComponent(filename);
        return '$_baseUrl/resize/$type/$folder/$encodedFilename$queryString';
      }
    }
    
    // Pour les menus ou les cas simples, encoder le chemin complet
    final encodedPath = Uri.encodeComponent(path);
    return '$_baseUrl/resize/$type/$encodedPath$queryString';
  }

  /// Construit une URL d'image originale (sans redimensionnement)
  static String buildOriginalImageUrl({
    required String type,
    required String path,
  }) {
    final encodedPath = Uri.encodeComponent(path);
    return '$_baseUrl/original/$type/$encodedPath';
  }

  /// Construit une URL pour obtenir les métadonnées d'une image
  static String buildMetadataUrl({
    required String type,
    required String path,
  }) {
    final encodedPath = Uri.encodeComponent(path);
    return '$_baseUrl/metadata/$type/$encodedPath';
  }

  /// Construit une URL d'image avec des dimensions prédéfinies pour les cartes
  static String buildCardImageUrl({
    required String type,
    required String path,
    required double width,
    required double height,
    int quality = 85,
  }) {
    return _buildImageUrl(
      type: type,
      path: path,
      width: width,
      height: height,
      quality: quality,
      format: 'jpeg',
      fit: 'cover',
    );
  }

  /// Construit une URL d'image avec des dimensions prédéfinies pour les thumbnails
  static String buildThumbnailUrl({
    required String type,
    required String path,
    double size = 150,
    int quality = 80,
  }) {
    return _buildImageUrl(
      type: type,
      path: path,
      width: size,
      height: size,
      quality: quality,
      format: 'jpeg',
      fit: 'cover',
    );
  }

  /// Construit une URL d'image avec des dimensions prédéfinies pour les avatars
  static String buildAvatarUrl({
    required String type,
    required String path,
    double size = 100,
    int quality = 90,
  }) {
    return _buildImageUrl(
      type: type,
      path: path,
      width: size,
      height: size,
      quality: quality,
      format: 'jpeg',
      fit: 'cover',
    );
  }

  /// Construit une URL d'image optimisée pour le web (format WebP)
  static String buildWebOptimizedUrl({
    required String type,
    required String path,
    double? width,
    double? height,
    int quality = 85,
  }) {
    return _buildImageUrl(
      type: type,
      path: path,
      width: width,
      height: height,
      quality: quality,
      format: 'webp',
      fit: 'cover',
    );
  }

  /// Vérifie si l'URL est une image locale ou externe
  static bool isLocalImage(String imagePath) {
    return !imagePath.startsWith('http://') && !imagePath.startsWith('https://');
  }

  /// Extrait le nom de fichier d'un chemin d'image
  static String getFileName(String imagePath) {
    return imagePath.split('/').last;
  }

  /// Extrait l'extension d'un nom de fichier
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Détermine si l'extension est une image supportée
  static bool isSupportedImageFormat(String extension) {
    const supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return supportedFormats.contains(extension.toLowerCase());
  }
}
