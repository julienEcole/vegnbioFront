import 'package:flutter/material.dart';
import '../services/image_url_service.dart';

class ResponsiveImageCard extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackBackgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets? margin;
  final BoxShadow? shadow;
  final Widget? overlay;
  final VoidCallback? onTap;
  final bool isCircular;
  final int imageQuality;
  final String imageFormat;
  final String imageFit;

  const ResponsiveImageCard({
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
    this.overlay,
    this.onTap,
    this.isCircular = false,
    this.imageQuality = 85,
    this.imageFormat = 'jpeg',
    this.imageFit = 'cover',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircular 
        ? BorderRadius.circular((width ?? height ?? 100) / 2)
        : (borderRadius ?? BorderRadius.circular(16));
    
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    Widget imageWidget = _buildImageWidget(context, effectiveBorderRadius, effectiveBorderColor);

    // Ajouter l'overlay si présent
    if (overlay != null) {
      imageWidget = Stack(
        children: [
          imageWidget,
          Positioned.fill(child: overlay!),
        ],
      );
    }

    // Ajouter le tap handler si présent
    if (onTap != null) {
      imageWidget = GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: imageWidget,
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, BorderRadius borderRadius, Color borderColor) {
    // Si pas d'URL d'image, afficher le fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context, borderRadius, borderColor);
    }

    // Construire l'URL optimisée avec dimensions
    final optimizedImageUrl = _buildOptimizedImageUrl();

    return Container(
      width: width,
      height: height,
      decoration: showBorder ? BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: borderRadius,
      ) : null,
      child: Image.network(
        optimizedImageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('Erreur de chargement de l\'image: $optimizedImageUrl - $error');
          return _buildFallback(context, borderRadius, borderColor);
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
                color: borderColor,
                width: borderWidth,
              ) : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit l'URL optimisée de l'image avec dimensions
  String _buildOptimizedImageUrl() {
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl!;
    }
    
    // Si c'est un chemin relatif, construire l'URL optimisée via l'API
    if (imageUrl!.contains('/')) {
      // Format: "Bastille/exterieur.png" → route restaurants
      return ImageUrlService.buildRestaurantImageUrl(
        imagePath: imageUrl!,
        width: width,
        height: height,
        quality: imageQuality,
        format: imageFormat,
        fit: imageFit,
      );
    } else {
      // Format: "Menu Ete Fraicheur.png" → route menus
      return ImageUrlService.buildMenuImageUrl(
        imageName: imageUrl!,
        width: width,
        height: height,
        quality: imageQuality,
        format: imageFormat,
        fit: imageFit,
      );
    }
  }

  Widget _buildFallback(BuildContext context, BorderRadius borderRadius, Color borderColor) {
    return Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fallbackIcon,
              size: (width != null && height != null) 
                  ? (width! + height!) / 8  // Taille proportionnelle
                  : 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Image non disponible',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
