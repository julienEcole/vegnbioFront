import 'package:flutter/material.dart';
import '../responsive_image_card.dart';
import '../../services/image_url_service.dart';

class MenuImageWidget extends StatelessWidget {
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
  final VoidCallback? onTap;
  final Widget? overlay;
  final int imageQuality;
  final String imageFormat;
  final String imageFit;

  const MenuImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain, // Changé de cover à contain pour mieux centrer les images
    this.borderRadius,
    this.fallbackIcon = Icons.restaurant_menu,
    this.fallbackBackgroundColor,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.5,
    this.margin,
    this.shadow,
    this.onTap,
    this.overlay,
    this.imageQuality = 90,
    this.imageFormat = 'jpeg',
    this.imageFit = 'contain', // Changé de cover à contain
  });

  @override
  Widget build(BuildContext context) {
    // Si pas d'image, afficher un placeholder élégant
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // Pour les images de menus, utiliser un centrage spécialisé
    if (imageUrl!.contains('Menu') || imageUrl!.contains('menu')) {
      return _buildMenuImageCard(context);
    }

    return ResponsiveImageCard(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      fallbackIcon: fallbackIcon,
      fallbackBackgroundColor: fallbackBackgroundColor,
      showBorder: showBorder,
      borderColor: borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
      borderWidth: borderWidth,
      margin: margin,
      shadow: shadow ?? BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 15,
        offset: const Offset(0, 6),
        spreadRadius: 2,
      ),
      onTap: onTap,
      overlay: overlay,
      imageQuality: imageQuality,
      imageFormat: imageFormat,
      imageFit: imageFit,
    );
  }

  // Widget spécialisé pour les images de menus avec meilleur centrage
  Widget _buildMenuImageCard(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 15,
      offset: const Offset(0, 6),
      spreadRadius: 2,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Container(
          // Fond subtil pour les images de menus
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: effectiveBorderRadius,
          ),
          child: Stack(
            children: [
              // Image centrée avec BoxFit.contain et centrage vertical optimisé
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: width ?? double.infinity,
                    maxHeight: height ?? double.infinity,
                  ),
                  child: Image.network(
                    _buildMenuImageUrl(),
                    fit: BoxFit.contain,
                    alignment: Alignment.center, // Centrage parfait
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(context);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Overlay si présent
              if (overlay != null) overlay!,
            ],
          ),
        ),
      ),
    );
  }

  // Construit l'URL optimisée pour les images de menus
  String _buildMenuImageUrl() {
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl!;
    }
    
    return ImageUrlService.buildMenuImageUrl(
      imageName: imageUrl!,
      width: width,
      height: height,
      quality: imageQuality,
      format: imageFormat,
      fit: 'contain', // Force contain pour les menus
    );
  }

  // Méthode statique pour créer un widget optimisé pour les cartes de menus
  static Widget createMenuCard({
    required String? imageUrl,
    required double width,
    double height = 200,
    BorderRadius? borderRadius,
    IconData fallbackIcon = Icons.restaurant_menu,
    Color? fallbackBackgroundColor,
    bool showBorder = true,
    Color? borderColor,
    double borderWidth = 1.5,
    EdgeInsets? margin,
    BoxShadow? shadow,
    VoidCallback? onTap,
    Widget? overlay,
    int imageQuality = 90,
    String imageFormat = 'jpeg',
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: shadow != null ? [shadow] : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Container(
          // Fond subtil pour les images de menus
          decoration: BoxDecoration(
            color: fallbackBackgroundColor ?? Colors.grey.shade50,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Image centrée avec BoxFit.contain et centrage parfait
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: width,
                    maxHeight: height,
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          _buildOptimizedMenuImageUrl(imageUrl!, width, height, imageQuality, imageFormat),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildMenuPlaceholder(width, height, fallbackIcon);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : _buildMenuPlaceholder(width, height, fallbackIcon),
                ),
              ),
              // Overlay si présent
              if (overlay != null) overlay!,
            ],
          ),
        ),
      ),
    );
  }

  // Construit l'URL optimisée pour les images de menus
  static String _buildOptimizedMenuImageUrl(String imageUrl, double width, double height, int quality, String format) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    return ImageUrlService.buildMenuImageUrl(
      imageName: imageUrl,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: 'contain',
    );
  }

  // Placeholder spécialisé pour les cartes de menus
  static Widget _buildMenuPlaceholder(double width, double height, IconData icon) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: (width + height) / 8,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune image',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'du menu',
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

  // Widget de démonstration pour tester les différents layouts
  static Widget createLayoutDemo({
    required String? imageUrl,
    required double containerWidth,
    double containerHeight = 300,
    BorderRadius? borderRadius,
    IconData fallbackIcon = Icons.restaurant_menu,
  }) {
    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200, width: 2),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: Colors.blue.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Layout Demo - Largeur: ${containerWidth.round()}px',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            containerWidth > 600 
                ? 'Layout Horizontal (Image à droite)'
                : containerWidth < 400
                    ? 'Layout Compact (Image au-dessus)'
                    : 'Layout Vertical (Image au-dessus)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 16),
          // Image de démonstration
          Container(
            width: containerWidth * 0.8,
            height: containerHeight * 0.6,
            child: createMenuCard(
              imageUrl: imageUrl,
              width: containerWidth * 0.8,
              height: containerHeight * 0.6,
              borderRadius: BorderRadius.circular(12),
              fallbackIcon: fallbackIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: fallbackBackgroundColor ?? Colors.grey.shade100,
        borderRadius: effectiveBorderRadius,
        border: showBorder ? Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
          style: BorderStyle.solid,
        ) : null,
        boxShadow: [effectiveShadow],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fallbackIcon,
                size: (width != null && height != null) 
                    ? (width! + height!) / 8
                    : 32,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune image',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'du menu',
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
