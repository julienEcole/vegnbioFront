import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String? newImageUrl) onImageUploaded;
  final String uploadType; // 'restaurant' ou 'menu'
  final int itemId;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ImageUploadWidget({
    Key? key,
    this.currentImageUrl,
    required this.onImageUploaded,
    required this.uploadType,
    required this.itemId,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isUploading = false;
  File? _selectedImageFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Stack(
        children: [
          // Image actuelle ou placeholder
          _buildImageDisplay(),
          
          // Overlay avec boutons d'action
          _buildActionOverlay(),
          
          // Indicateur de chargement
          if (_isUploading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImageFile != null) {
      // Image sélectionnée localement (pas encore uploadée)
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Image.file(
          _selectedImageFile!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      // Image existante sur le serveur
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Image.network(
          widget.currentImageUrl!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      // Aucune image
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.uploadType == 'restaurant' ? Icons.restaurant : Icons.restaurant_menu,
            size: 48,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune image',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton pour sélectionner une image
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: Text(_selectedImageFile != null ? 'Changer' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              
              if (_selectedImageFile != null) ...[
                const SizedBox(width: 8),
                // Bouton pour uploader l'image sélectionnée
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Envoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
              
              if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                // Bouton pour supprimer l'image
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _removeImage,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.7),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Upload en cours...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final XFile? selectedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (selectedFile != null) {
        setState(() {
          _selectedImageFile = File(selectedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic> response;

      if (widget.uploadType == 'restaurant') {
        response = await _apiService.uploadRestaurantImage(widget.itemId, _selectedImageFile!);
      } else {
        response = await _apiService.uploadMenuImage(widget.itemId, _selectedImageFile!);
      }

      if (response['success'] == true) {
        final newImageUrl = response['imageUrl'] as String?;
        widget.onImageUploaded(newImageUrl);
        
        setState(() {
          _selectedImageFile = null; // Réinitialiser la sélection locale
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploadée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
    });
    widget.onImageUploaded(null);
  }
}


