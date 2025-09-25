import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackBackgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets? margin;
  final BoxShadow? shadow;

  const ImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported,
    this.fallbackBackgroundColor,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.margin,
    this.shadow,
  });

  /// Construit l'URL complète de l'image
  String _buildFullImageUrl(String imageUrl) {
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Si c'est un chemin relatif, construire l'URL via l'API
    // En production, le frontend et le backend seront sur des serveurs séparés
    // donc on utilise la route API dédiée
    
    // Détecter le type d'image basé sur le chemin
    if (imageUrl.contains('/')) {
      // Format: "Bastille/exterieur.png" → route restaurants
      return '/api/images/restaurants/$imageUrl';
    } else {
      // Format: "Menu Ete Fraicheur.png" → route menus
      return '/api/images/menus/$imageUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(12);
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withOpacity(0.3);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
    
    // Si pas d'URL d'image, afficher le fallback directement
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context, borderRadius, effectiveBorderColor, effectiveShadow);
    }

    // Construire l'URL complète
    final fullImageUrl = _buildFullImageUrl(imageUrl!);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: width,
          height: height,
          decoration: showBorder ? BoxDecoration(
            border: Border.all(
              color: effectiveBorderColor,
              width: borderWidth,
            ),
            borderRadius: borderRadius,
          ) : null,
          child: Image.network(
            fullImageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              print('Erreur de chargement de l\'image: $fullImageUrl - $error');
              return _buildFallback(context, borderRadius, effectiveBorderColor, effectiveShadow);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: borderRadius,
                  border: showBorder ? Border.all(
                    color: effectiveBorderColor,
                    width: borderWidth,
                  ) : null,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, BorderRadius borderRadius, Color borderColor, BoxShadow shadow) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [shadow],
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fallbackBackgroundColor ?? Colors.grey.shade200,
          borderRadius: borderRadius,
          border: showBorder ? Border.all(
            color: borderColor,
            width: borderWidth,
          ) : null,
        ),
        child: Center(
          child: Icon(
            fallbackIcon,
            size: (width != null && height != null) 
                ? (width! + height!) / 6  // Taille proportionnelle
                : 40,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
