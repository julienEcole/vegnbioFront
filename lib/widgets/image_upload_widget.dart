import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// ATTENTION: `dart:io` n'est utilisé QUE hors Web.
/// On le garde importé pour mobile/desktop (le build Web ignore réellement File).
/// Si jamais ton build Web râle, bascule vers un import conditionnel.
/// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show File;

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

  // Sélection locale (selon plateforme)
  File? _selectedFile;            // mobile/desktop
  Uint8List? _selectedBytes;      // web
  String? _pickedFilename;        // web (conserve l'extension/mime)

  bool get _hasLocalSelection =>
      kIsWeb ? _selectedBytes != null : _selectedFile != null;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            _buildImageDisplay(),
            _buildActionOverlay(),
            if (_isUploading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  // --- PREVIEW ---------------------------------------------------------------

  Widget _buildImageDisplay() {
    // 1) Preview local (sélection en cours)
    if (_hasLocalSelection) {
      if (kIsWeb && _selectedBytes != null) {
        return Image.memory(
          _selectedBytes!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        );
      }
      if (!kIsWeb && _selectedFile != null) {
        return Image.file(
          _selectedFile!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        );
      }
    }

    // 2) Image distante existante
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // 3) Placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.withOpacity(0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.uploadType == 'restaurant'
                ? Icons.restaurant
                : Icons.restaurant_menu,
            size: 42,
            color: Colors.grey.withOpacity(0.55),
          ),
          const SizedBox(height: 6),
          Text(
            'Aucune image',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS UI ------------------------------------------------------------

  Widget _buildActionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.18),
        child: Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Sélection
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: Text(_hasLocalSelection ? 'Changer' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // Envoyer (visible si une image est sélectionnée localement)
              if (_hasLocalSelection)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Envoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),

              // Supprimer (si image distante existe)
              if (widget.currentImageUrl != null &&
                  widget.currentImageUrl!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _removeImage,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10),
              Text(
                'Upload en cours...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIQUE ---------------------------------------------------------------

  Future<void> _selectImage() async {
    try {
      final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (picked == null) return;

      if (kIsWeb) {
        // Web: on lit bytes + nom
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedBytes = bytes;
          _pickedFilename = picked.name; // ex: photo.png
          _selectedFile = null; // reset
        });
      } else {
        // Mobile/Desktop: on stocke le File
        setState(() {
          _selectedFile = File(picked.path);
          _selectedBytes = null;
          _pickedFilename = null;
        });
      }
    } catch (e) {
      _snack('Erreur lors de la sélection: $e', isError: true);
    }
  }

  Future<void> _uploadImage() async {
    if (!_hasLocalSelection) return;

    setState(() => _isUploading = true);

    try {
      Map<String, dynamic> resp;

      final isMenu = widget.uploadType == 'menu';

      if (kIsWeb) {
        // --- WEB: upload via bytes ---
        if (_selectedBytes == null) return;
        final filename = _pickedFilename ?? 'upload.jpg';

        if (isMenu) {
          resp = await _apiService.uploadMenuImageBytes(
            widget.itemId,
            _selectedBytes!,
            filename,
          );
        } else {
          resp = await _apiService.uploadRestaurantImageBytes(
            widget.itemId,
            _selectedBytes!,
            filename,
          );
        }
      } else {
        // --- MOBILE/DESKTOP: upload via File ---
        if (_selectedFile == null) return;

        if (isMenu) {
          resp = await _apiService.uploadMenuImage(widget.itemId, _selectedFile!);
        } else {
          resp = await _apiService.uploadRestaurantImage(
              widget.itemId, _selectedFile!);
        }
      }

      if (resp['success'] == true) {
        final newUrl = resp['imageUrl'] as String?;
        widget.onImageUploaded(newUrl);

        setState(() {
          _selectedFile = null;
          _selectedBytes = null;
          _pickedFilename = null;
        });

        _snack('Image uploadée avec succès !');
      } else {
        throw Exception(resp['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      _snack('Erreur lors de l’upload: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFile = null;
      _selectedBytes = null;
      _pickedFilename = null;
    });
    widget.onImageUploaded(null);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
