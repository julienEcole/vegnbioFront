import 'package:flutter/material.dart';
import '../../models/restaurant_image.dart';
import '../common/responsive_image_card.dart';

class RestaurantImagesWidget extends StatefulWidget {
  final List<RestaurantImage>? images;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final BoxFit? fit;
  final Color? borderColor;
  final double? borderWidth;
  final bool showBorder;
  final BoxShadow? shadow;
  final Function(RestaurantImage)? onImageTap;
  final bool enableHorizontalScroll;
  final bool showAllImages;
  final bool enableNavigationArrows;

  const RestaurantImagesWidget({
    super.key,
    this.images,
    this.width,
    this.height,
    this.margin,
    this.borderRadius,
    this.fit,
    this.borderColor,
    this.borderWidth,
    this.showBorder = false,
    this.shadow,
    this.onImageTap,
    this.enableHorizontalScroll = false,
    this.showAllImages = false,
    this.enableNavigationArrows = false,
  });

  @override
  State<RestaurantImagesWidget> createState() => _RestaurantImagesWidgetState();
}

class _RestaurantImagesWidgetState extends State<RestaurantImagesWidget> {
  int? selectedImageIndex;
  late ScrollController _scrollController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gestion robuste : 0 à n images
    if (widget.images == null || widget.images!.isEmpty) {
      return _buildFallback(context);
    }

    // Nouveau mode : galerie scrollable horizontale
    if (widget.enableHorizontalScroll && widget.images != null && widget.images!.isNotEmpty) {
      return _buildHorizontalGallery(context);
    }

    // Nouveau mode : navigation horizontale avec flèches
    if (widget.enableNavigationArrows && widget.images != null && widget.images!.isNotEmpty) {
      return _buildNavigationArrows(context);
    }

    // Nouveau mode : afficher toutes les images en grille
    if (widget.showAllImages && widget.images != null && widget.images!.isNotEmpty) {
      return _buildAllImagesGrid(context);
    }

    if (widget.showMultipleImages && widget.images!.length > 1) {
      return _buildMultipleImages(context);
    }

    // Afficher l'image principale ou la première image
    final image = widget.images!.firstWhere(
      (img) => img.isPrimary,
      orElse: () => widget.images!.first,
    );

    return _buildSingleImage(context, image);
  }

  Widget _buildAllImagesGrid(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    // Détecter la taille d'écran et adapter les dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final imageCount = widget.images!.length;
    
    // Calculer la largeur de chaque image pour qu'elles prennent plus de place
    double imageWidth;
    double imageHeight;
    
    // Calculer la largeur totale disponible (en tenant compte du container)
    final containerWidth = widget.width ?? screenWidth;
    
    if (isMobile) {
      // Mobile : images plus larges pour prendre plus de place
      imageWidth = (containerWidth * 0.4).clamp(140.0, 200.0);
      imageHeight = widget.height ?? imageWidth;
    } else if (isTablet) {
      // Tablette : images plus larges
      imageWidth = (containerWidth * 0.3).clamp(160.0, 250.0);
      imageHeight = widget.height ?? imageWidth;
    } else {
      // Desktop : images encore plus larges
      imageWidth = (containerWidth * 0.25).clamp(180.0, 300.0);
      imageHeight = widget.height ?? imageWidth;
    }
    
    // Espacement réduit pour que les images prennent plus de place
    final spacing = isMobile ? 6.0 : (isTablet ? 8.0 : 10.0);

    // Calculer la largeur totale nécessaire pour toutes les images
    final totalWidth = (imageWidth * imageCount) + (spacing * (imageCount - 1));
    
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: totalWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int index = 0; index < imageCount; index++) ...[
                  if (index > 0) SizedBox(width: spacing), // Espacement réduit entre images
                  Container(
                    width: imageWidth,
                    height: imageHeight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () {
                          if (widget.onImageTap != null) {
                            widget.onImageTap!(widget.images![index]);
                          } else {
                            _showImageFullScreen(context, widget.images![index]);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            ResponsiveImageCard(
                              imageUrl: widget.images![index].imageUrl,
                              width: imageWidth,
                              height: imageHeight,
                              fit: widget.fit ?? BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                              fallbackIcon: Icons.restaurant,
                              showBorder: false,
                              onTap: null,
                              isCircular: false,
                            ),
                            if (widget.images![index].isPrimary)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : (isTablet ? 7 : 8),
                                    vertical: isMobile ? 3 : (isTablet ? 3.5 : 4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(isMobile ? 8 : (isTablet ? 9 : 10)),
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
                                        size: isMobile ? 10 : (isTablet ? 11 : 12),
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: isMobile ? 2 : (isTablet ? 3 : 4)),
                                      Text(
                                        'Principale',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 8 : (isTablet ? 9 : 10),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Description de l'image
                            if (widget.images![index].description != null && 
                                widget.images![index].description!.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 6 : (isTablet ? 7 : 8)),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black87,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    widget.images![index].description!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 8 : (isTablet ? 9 : 10),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, RestaurantImage image) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              if (widget.onImageTap != null) {
                widget.onImageTap!(image);
              } else {
                _showImageFullScreen(context, image);
              }
            },
            borderRadius: borderRadius,
            child: ResponsiveImageCard(
              imageUrl: image.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit ?? BoxFit.cover,
              borderRadius: borderRadius,
              fallbackIcon: Icons.restaurant,
              showBorder: widget.showBorder,
              borderColor: widget.borderColor,
              borderWidth: widget.borderWidth,
              onTap: null, // Géré par InkWell
              isCircular: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Image principale
            ResponsiveImageCard(
              imageUrl: widget.images!.first.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit ?? BoxFit.cover,
              borderRadius: borderRadius,
              fallbackIcon: Icons.restaurant,
              showBorder: false,
              onTap: () {
                if (widget.onImageTap != null) {
                  widget.onImageTap!(widget.images!.first);
                } else {
                  _showImageFullScreen(context, widget.images!.first);
                }
              },
              isCircular: false,
            ),
            
            // Badge "+X images"
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
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
                      '+${widget.images!.length - 1}',
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
            if (widget.images!.length > 2) ...[
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

  Widget _buildHorizontalGallery(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.images!.map((image) {
              return Container(
                width: widget.width! / 3,
                height: widget.height,
                margin: const EdgeInsets.only(right: 8),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () {
                      if (widget.onImageTap != null) {
                        widget.onImageTap!(image);
                      } else {
                        _showImageFullScreen(context, image);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: ResponsiveImageCard(
                      imageUrl: image.imageUrl,
                      width: widget.width! / 3,
                      height: widget.height,
                      fit: widget.fit ?? BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      fallbackIcon: Icons.restaurant,
                      showBorder: false,
                      onTap: null,
                      isCircular: false,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrows(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );

    // Détecter la taille d'écran et adapter les dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final imageCount = widget.images!.length;
    
    // Calculer les dimensions des éléments selon la taille d'écran
    final arrowSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final arrowPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final indicatorSize = isMobile ? 8.0 : (isTablet ? 9.0 : 10.0);
    final indicatorMargin = isMobile ? 3.0 : (isTablet ? 3.5 : 4.0);
    final counterPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    final counterFontSize = isMobile ? 10.0 : (isTablet ? 11.0 : 12.0);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [effectiveShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Images principales
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  selectedImageIndex = index;
                });
              },
              itemCount: imageCount,
              itemBuilder: (context, index) {
                final image = widget.images![index];
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      // Image principale
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: InkWell(
                          onTap: () {
                            if (widget.onImageTap != null) {
                              widget.onImageTap!(image);
                            } else {
                              _showImageFullScreen(context, image);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: ResponsiveImageCard(
                            imageUrl: image.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: widget.fit ?? BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                            fallbackIcon: Icons.restaurant,
                            showBorder: false,
                            onTap: null,
                            isCircular: false,
                          ),
                        ),
                      ),
                      
                      // Indicateur d'image principale
                      if (image.isPrimary)
                        Positioned(
                          top: 12,
                          left: 12,
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
                      
                      // Description de l'image
                      if (image.description != null && image.description!.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              image.description!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // Flèche gauche
            if (imageCount > 1)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (selectedImageIndex != null && selectedImageIndex! > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(arrowPadding),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(isMobile ? 20 : 25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: arrowSize,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Flèche droite
            if (imageCount > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (selectedImageIndex != null && selectedImageIndex! < imageCount - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(arrowPadding),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(isMobile ? 20 : 25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: arrowSize,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Indicateurs de navigation en bas
            if (imageCount > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < imageCount; i++)
                      GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: indicatorSize,
                          height: indicatorSize,
                          margin: EdgeInsets.symmetric(horizontal: indicatorMargin),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == selectedImageIndex 
                                ? Colors.white 
                                : Colors.white.withValues(alpha: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            
            // Compteur d'images
            if (imageCount > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: counterPadding,
                    vertical: counterPadding * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${(selectedImageIndex ?? 0) + 1}/$imageCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: counterFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
    
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
        border: widget.showBorder ? Border.all(
          color: widget.borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: widget.borderWidth ?? 1,
        ) : null,
        boxShadow: [effectiveShadow],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: (widget.width != null && widget.height != null) 
                  ? (widget.width! + widget.height!) / 6
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

  void _showImageFullScreen(BuildContext context, RestaurantImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
