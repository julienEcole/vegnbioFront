import 'package:flutter/material.dart';
import 'responsive_image_card.dart';
import '../services/image_url_service.dart';

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
    this.fit = BoxFit.cover,
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
    this.imageFit = 'cover',
  });

  @override
  Widget build(BuildContext context) {
    // Si pas d'image, afficher un placeholder élégant
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
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
