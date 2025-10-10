import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/restaurant_image.dart';
import 'package:vegnbio_front/widgets/image_upload_widget.dart';
import 'package:vegnbio_front/services/api_service.dart';

/// Widget de gestion des images multiples d'un restaurant
class RestaurantImagesManager extends ConsumerStatefulWidget {
  final int restaurantId;
  final List<RestaurantImage>? initialImages;
  final Function(List<RestaurantImage>)? onImagesChanged;

  const RestaurantImagesManager({
    super.key,
    required this.restaurantId,
    this.initialImages,
    this.onImagesChanged,
  });

  @override
  ConsumerState<RestaurantImagesManager> createState() => _RestaurantImagesManagerState();
}

class _RestaurantImagesManagerState extends ConsumerState<RestaurantImagesManager> {
  List<RestaurantImage> _images = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _images = widget.initialImages ?? [];
    // Toujours recharger les images depuis l'API pour avoir les données les plus récentes
    if (widget.restaurantId > 0) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    if (widget.restaurantId == 0) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final imagesList = await apiService.getRestaurantImages(widget.restaurantId);
      
      setState(() {
        _images = imagesList
            .map((json) => RestaurantImage.fromJson(json))
            .toList();
        _images.sort((a, b) {
          if (a.isPrimary) return -1;
          if (b.isPrimary) return 1;
          return a.ordre.compareTo(b.ordre);
        });
      });
      widget.onImagesChanged?.call(_images);
    } catch (e) {
      setState(() => _error = 'Erreur lors du chargement des images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteImage(RestaurantImage image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image'),
        content: const Text('Voulez-vous vraiment supprimer cette image ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final success = await apiService.deleteRestaurantImage(widget.restaurantId, image.id);
      
      if (success) {
        setState(() {
          _images.removeWhere((img) => img.id == image.id);
        });
        
        widget.onImagesChanged?.call(_images);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setPrimaryImage(RestaurantImage image) async {
    if (image.isPrimary) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final success = await apiService.setRestaurantPrimaryImage(widget.restaurantId, image.id);
      
      if (success) {
        setState(() {
          for (var img in _images) {
            img.isPrimary = img.id == image.id;
          }
          _images.sort((a, b) {
            if (a.isPrimary) return -1;
            if (b.isPrimary) return 1;
            return a.ordre.compareTo(b.ordre);
          });
        });
        
        widget.onImagesChanged?.call(_images);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image principale mise à jour'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restaurantId == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Créez d\'abord le restaurant pour pouvoir ajouter des images',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // Liste des images existantes
        if (_images.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Images du restaurant (${_images.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _images.map((image) => _buildImageCard(image)).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
          ),

        // Widget d'ajout de nouvelle image
        Text(
          'Ajouter une nouvelle image',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ImageUploadWidget(
              currentImageUrl: null,
              onImageUploaded: (imageUrl) {
                if (imageUrl != null) {
                  _onNewImageUploaded(imageUrl);
                }
              },
              uploadType: 'restaurant',
              itemId: widget.restaurantId,
              width: double.infinity,
              height: 200,
            ),
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCard(RestaurantImage image) {
    return Container(
      width: 200,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: image.isPrimary ? Colors.green : Colors.grey.shade300,
          width: image.isPrimary ? 3 : 1,
        ),
      ),
      child: Column(
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                ),
                // Badge image principale
                if (image.isPrimary)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRINCIPALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: image.isPrimary 
                  ? Colors.green.shade50 
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!image.isPrimary)
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.star_outline, size: 20),
                      tooltip: 'Définir comme principale',
                      onPressed: _isLoading ? null : () => _setPrimaryImage(image),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                if (image.isPrimary)
                  const Expanded(
                    child: Icon(
                      Icons.star,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Supprimer',
                    onPressed: _isLoading ? null : () => _deleteImage(image),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onNewImageUploaded(String imageUrl) {
    // Ajouter immédiatement l'image à la liste locale pour un feedback visuel rapide
    final newImage = RestaurantImage(
      id: DateTime.now().millisecondsSinceEpoch, // ID temporaire
      restaurantId: widget.restaurantId,
      imageUrl: imageUrl,
      description: 'Image du restaurant',
      ordre: _images.length + 1,
      isPrimary: _images.isEmpty, // Première image = principale
    );
    
    setState(() {
      _images.add(newImage);
      // Si c'est la première image, elle devient principale
      if (newImage.isPrimary) {
        for (int i = 0; i < _images.length - 1; i++) {
          _images[i].isPrimary = false;
        }
      }
    });
    
    // Rafraîchir depuis l'API en arrière-plan pour avoir les vraies données
    _loadImages();
  }
}

