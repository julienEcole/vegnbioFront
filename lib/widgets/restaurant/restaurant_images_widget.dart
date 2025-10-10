import 'package:flutter/material.dart';
import '../../models/restaurant_image.dart';
import '../common/responsive_image_card.dart';

class RestaurantImagesWidget extends StatefulWidget {
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
  State<RestaurantImagesWidget> createState() => _RestaurantImagesWidgetState();
}

class _RestaurantImagesWidgetState extends State<RestaurantImagesWidget> {
  int? selectedImageIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Widget _buildHorizontalGallery(BuildContext context) {
    // Sécurité
    if (widget.images == null || widget.images!.isEmpty) {
      return _buildFallback(context);
    }

    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveShadow = widget.shadow ??
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // width FINIE (évite double.infinity en liste)
        final effectiveWidth = (widget.width != null && widget.width!.isFinite)
            ? widget.width!
            : (constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width);
        final itemWidth = 280.0; // largeur d’une vignette
        const itemSpacing = 12.0;

        return SizedBox(
          width: effectiveWidth,
          height: widget.height, // doit être fixé par le parent
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [effectiveShadow],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                children: [
                  // ✅ Remplacement: ListView.builder horizontal
                  ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    primary: false,         // important dans une liste parente
                    shrinkWrap: true,       // borne la taille
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: widget.images!.length,
                    itemBuilder: (context, index) {
                      final image = widget.images![index];
                      final isSelected = selectedImageIndex == index;

                      return Container(
                        width: itemWidth,
                        margin: EdgeInsets.only(
                          right: index == widget.images!.length - 1 ? 0 : itemSpacing,
                        ),
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() => selectedImageIndex = index);
                                if (widget.onImageTap != null) {
                                  widget.onImageTap!(image);
                                } else {
                                  _showImageFullScreen(context, image);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: ResponsiveImageCard(
                                imageUrl: image.imageUrl,
                                width: itemWidth,
                                height: double.infinity,
                                fit: widget.fit ?? BoxFit.cover,
                                borderRadius: BorderRadius.circular(8),
                                fallbackIcon: Icons.restaurant,
                                showBorder: false,
                                onTap: null, // géré par InkWell
                                isCircular: false,
                              ),
                            ),

                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Flèche droite
                  if (widget.images!.length > 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.offset + (itemWidth + itemSpacing),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),

                  // Flèche gauche
                  if (widget.images!.length > 1)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                (_scrollController.offset - (itemWidth + itemSpacing)).clamp(0.0, double.infinity),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),

                  // Indicateurs (facultatif)
                  if (widget.images!.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.images!.length, (i) {
                            final active = i == selectedImageIndex;
                            return GestureDetector(
                              onTap: () {
                                if (_scrollController.hasClients) {
                                  final target = i * (itemWidth + itemSpacing);
                                  _scrollController.animateTo(
                                    target,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  setState(() => selectedImageIndex = i);
                                }
                              },
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active ? Colors.white : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildSingleImage(BuildContext context, RestaurantImage image) {
    return ResponsiveImageCard(
      imageUrl: image.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      borderRadius: widget.borderRadius,
      fallbackIcon: Icons.restaurant,
      showBorder: widget.showBorder,
      borderColor: widget.borderColor,
      borderWidth: widget.borderWidth,
      onTap: widget.onImageTap != null ? () => widget.onImageTap!(image) : () => _showImageFullScreen(context, image),
      isCircular: widget.isCircular,
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = widget.borderColor ?? Theme.of(context).colorScheme.outline.withOpacity(0.3);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    );
    
    return Container(
      width: widget.width,
      height: widget.height,
      child: Container(
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
              imageUrl: widget.images!.first.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit ?? BoxFit.cover,
              borderRadius: borderRadius,
              fallbackIcon: Icons.restaurant,
              showBorder: false, // Pas de bordure car géré par le conteneur parent
              isCircular: widget.isCircular,
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
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = widget.borderColor ?? Theme.of(context).colorScheme.outline.withOpacity(0.3);
    final effectiveShadow = widget.shadow ?? BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
        border: widget.showBorder ? Border.all(
          color: effectiveBorderColor,
          width: widget.borderWidth,
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
