import 'package:flutter/material.dart';
import '../../models/restaurant_image.dart';
import '../common/responsive_image_card.dart';

class RestaurantGalleryWidget extends StatelessWidget {
  final List<RestaurantImage>? images;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Function(RestaurantImage)? onImageTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets? margin;
  final BoxShadow? shadow;
  final double imageSpacing;
  final double imageHeight;
  final bool showImageCount;

  const RestaurantGalleryWidget({
    super.key,
    this.images,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onImageTap,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.margin,
    this.shadow,
    this.imageSpacing = 12.0,
    this.imageHeight = 180.0,
    this.showImageCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (images == null || images!.isEmpty) {
      return _buildFallback(context);
    }

    if (images!.length == 1) {
      return _buildSingleImage(context, images!.first);
    }

    return _buildHorizontalGallery(context);
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
      height: height ?? imageHeight + 60, // Hauteur pour images + indicateurs + descriptions
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: images!.length,
                itemBuilder: (context, index) {
                  final image = images![index];
                  final isPrimary = image.isPrimary;
                  
                  return Container(
                    margin: EdgeInsets.only(
                      right: index < images!.length - 1 ? imageSpacing : 0,
                    ),
                    child: Column(
                      children: [
                        // Image avec indicateur si c'est l'image principale
                        Stack(
                          children: [
                            ResponsiveImageCard(
                              imageUrl: image.imageUrl,
                              width: imageHeight * 1.3, // Ratio 4:3 légèrement plus large
                              height: imageHeight,
                              fit: fit ?? BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                              fallbackIcon: Icons.restaurant,
                              showBorder: showBorder,
                              borderColor: effectiveBorderColor,
                              borderWidth: borderWidth,
                              onTap: onImageTap != null ? () => onImageTap!(image) : null,
                              isCircular: false,
                            ),
                            
                            // Indicateur d'image principale
                            if (isPrimary)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Principale',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Description de l'image
                        if (image.description != null && image.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: imageHeight * 1.3,
                            child: Text(
                              image.description!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicateur du nombre d'images
            if (showImageCount && images!.length > 1)
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
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${images!.length} images',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      onTap: onImageTap != null ? () => onImageTap!(image) : null,
      isCircular: false,
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
      height: height ?? imageHeight + 40,
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
              size: 40,
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
