import 'package:flutter/material.dart';
import '../models/restaurant_image.dart';
import 'responsive_image_card.dart';

class RestaurantImagesWidget extends StatelessWidget {
  final List<RestaurantImage>? images;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final bool showMultipleImages;
  final Function(RestaurantImage)? onImageTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets? margin;
  final BoxShadow? shadow;
  final bool isCircular;
  final bool enableHorizontalScroll; // Nouveau paramètre

  const RestaurantImagesWidget({
    super.key,
    this.images,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showMultipleImages = false,
    this.onImageTap,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.margin,
    this.shadow,
    this.isCircular = false,
    this.enableHorizontalScroll = false, // Nouveau paramètre
  });

  @override
  Widget build(BuildContext context) {
    // Gestion robuste : 0 à n images
    if (images == null || images!.isEmpty) {
      return _buildFallback(context);
    }

    // Nouveau mode : galerie scrollable horizontale
    if (enableHorizontalScroll && images!.length > 1) {
      return _buildHorizontalGallery(context);
    }

    if (showMultipleImages && images!.length > 1) {
      return _buildMultipleImages(context);
    }

    // Afficher l'image principale ou la première image
    final image = images!.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images!.first,
    );

    return _buildSingleImage(context, image);
  }

  Widget _buildHorizontalGallery(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          children: [
            // Galerie scrollable horizontale
            Expanded(
              child: PageView.builder(
                itemCount: images!.length,
                itemBuilder: (context, index) {
                  final image = images![index];
                  return ResponsiveImageCard(
                    imageUrl: image.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: fit ?? BoxFit.cover,
                    borderRadius: BorderRadius.zero, // Pas de borderRadius pour PageView
                    fallbackIcon: Icons.restaurant,
                    showBorder: false,
                    onTap: onImageTap != null ? () => onImageTap!(image) : null,
                    isCircular: false,
                  );
                },
              ),
            ),
            
            // Indicateurs de navigation en bas
            if (images!.length > 1) ...[
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < images!.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, RestaurantImage image) {
    return ResponsiveImageCard(
      imageUrl: image.imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      borderRadius: borderRadius,
      fallbackIcon: Icons.restaurant,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      margin: margin,
      shadow: shadow,
      onTap: onImageTap != null ? () => onImageTap!(image) : null,
      isCircular: isCircular,
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    final effectiveShadow = shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Image principale (première)
            ResponsiveImageCard(
              imageUrl: images!.first.imageUrl,
              width: width,
              height: height,
              fit: fit ?? BoxFit.cover,
              borderRadius: borderRadius,
              fallbackIcon: Icons.restaurant,
              showBorder: false, // Pas de bordure car géré par le conteneur parent
              isCircular: isCircular,
            ),
            
            // Overlay avec indicateur de plusieurs images
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${images!.length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Indicateur de navigation si plus de 2 images
            if (images!.length > 2) ...[
              // Flèche gauche
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // Flèche droite
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(16);
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
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
        border: showBorder ? Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ) : null,
        boxShadow: [effectiveShadow],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: (width != null && height != null) 
                  ? (width! + height!) / 6
                  : 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune image',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'disponible',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
