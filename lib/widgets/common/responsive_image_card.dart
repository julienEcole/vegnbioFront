import 'package:flutter/material.dart';

class ResponsiveImageCard extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final IconData? fallbackIcon;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final bool isCircular;

  const ResponsiveImageCard({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.fallbackIcon,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: isCircular ? null : borderRadius,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        border: showBorder ? Border.all(
          color: borderColor ?? Colors.grey,
          width: borderWidth ?? 1,
        ) : null,
      ),
      child: ClipRRect(
        borderRadius: isCircular ? BorderRadius.zero : (borderRadius ?? BorderRadius.zero),
        child: GestureDetector(
          onTap: onTap,
          child: Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Icon(
                  fallbackIcon ?? Icons.image,
                  size: (width != null && height != null) ? 
                    ((width! + height!) / 6).clamp(24.0, 64.0) : 32,
                  color: Colors.grey[400],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
