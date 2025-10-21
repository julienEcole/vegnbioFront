import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/product_allergen_selector.dart';
import '../../models/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';

/// Écran de formulaire pour créer ou modifier un menu
/// (même logique, UI améliorée + contenu centré)
class MenuFormScreen extends ConsumerStatefulWidget {
  final Menu? menuToEdit;
  final int? defaultRestaurantId; // Restaurant par défaut lors de la création

  const MenuFormScreen({
    super.key, 
    this.menuToEdit,
    this.defaultRestaurantId,
  });

  @override
  ConsumerState<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends ConsumerState<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _prixController = TextEditingController();

  List<String> _selectedAllergenes = [];
  List<String> _selectedProduits = [];
  List<String> _availableAllergenes = [];
  List<String> _availableProduits = [];
  List<Restaurant> _restaurants = [];
  int? _selectedRestaurantId;
  String? _imageUrl;
  bool _isLoading = false;
  bool _disponible = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.menuToEdit != null) {
      _initializeFormWithMenu(widget.menuToEdit!);
    } else {
      _initializeEmptyForm();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final apiService = ApiService();
      final restaurants = await apiService.getRestaurants();
      final menus = await apiService.getMenus();

      setState(() {
        _restaurants = restaurants;

        final allAllergenes = <String>{};
        final allProduits = <String>{};
        for (final m in menus) {
          allAllergenes.addAll(m.allergenes);
          allProduits.addAll(m.produits);
        }

        allAllergenes.addAll([
          'Gluten', 'Lactose', 'Œufs', 'Arachides', 'Fruits à coque',
          'Soja', 'Poisson', 'Crustacés', 'Mollusques', 'Céleri',
          'Moutarde', 'Sésame', 'Sulfites', 'Lupin'
        ]);
        allProduits.addAll([
          'Légumes bio', 'Fruits bio', 'Céréales complètes', 'Protéines végétales',
          'Épices bio', 'Huiles bio', 'Herbes fraîches', 'Graines bio',
          'Légumineuses', 'Champignons bio', 'Algues', 'Noix bio'
        ]);

        _availableAllergenes = allAllergenes.toList()..sort();
        _availableProduits = allProduits.toList()..sort();

        // s'il n'y avait pas encore de restaurants au moment de _initializeEmptyForm
        if (widget.menuToEdit == null && _selectedRestaurantId == null && _restaurants.isNotEmpty) {
          // Utiliser le restaurant par défaut si fourni, sinon le premier
          _selectedRestaurantId = widget.defaultRestaurantId ?? _restaurants.first.id;
        }
      });
    } catch (e) {
      // Pas d’UI d’erreur ici volontairement (on reste léger)
      // debugPrint('Erreur _loadInitialData: $e');
    }
  }

  void _initializeFormWithMenu(Menu menu) {
    _titreController.text = menu.titre;
    _descriptionController.text = menu.description ?? '';
    _dateController.text = menu.date.toString().split(' ')[0];
    _prixController.text = menu.prix.toString();
    _selectedRestaurantId = menu.restaurantId;
    _imageUrl = menu.imageUrl;
    _disponible = menu.disponible;

    _selectedAllergenes = List.from(menu.allergenes);
    _selectedProduits = List.from(menu.produits);
  }

  void _initializeEmptyForm() {
    final now = DateTime.now();
    _dateController.text =
    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _prixController.text = '0.00';
    // _selectedRestaurantId sera défini après _loadInitialData si vide
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un restaurant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      if (widget.menuToEdit != null) {
        // Modification d'un menu existant
        await apiService.updateMenu(
          id: widget.menuToEdit!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          date: DateTime.parse(_dateController.text),
          allergenes: _selectedAllergenes,
          produits: _selectedProduits,
          restaurantId: _selectedRestaurantId!,
          prix: double.parse(_prixController.text),
          disponible: _disponible,
          imageUrl: _imageUrl,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu modifié avec succès')),
        );
      } else {
        // Création d'un nouveau menu
        await apiService.createMenu(
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          date: DateTime.parse(_dateController.text),
          allergenes: _selectedAllergenes,
          produits: _selectedProduits,
          restaurantId: _selectedRestaurantId!,
          prix: double.parse(_prixController.text),
          disponible: _disponible,
          imageUrl: null, // Pas d'image à la création
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu créé avec succès. Vous pouvez maintenant ajouter une image.')),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le menu "${widget.menuToEdit?.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteMenu();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenu() async {
    if (widget.menuToEdit == null) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.deleteMenu(widget.menuToEdit!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu "${widget.menuToEdit!.titre}" supprimé avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================

  // Conteneur centré + largeur max (évite full-width sur web)
  Widget _centeredShell({required Widget child}) {
    const maxWidth = 900.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  // Petite étiquette de section
  Widget _sectionLabel(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le menu' : 'Nouveau menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Supprimer le menu',
            ),
        ],
      ),
      body: _centeredShell(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, // espace clavier
            ),
            child: Card(

              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header visuel
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Modifier un menu' : 'Créer un menu',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bloc 1 — Infos principales
                      _sectionLabel('Informations principales', icon: Icons.info_outline),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _titreController,
                                decoration: const InputDecoration(
                                  labelText: '🍽️ Titre du menu *',
                                  hintText: 'Ex: Menu Végétarien Bio',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le titre est obligatoire' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: '📝 Description',
                                  hintText: 'Description du menu...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bloc 2 — Restaurant / Date / Prix / Disponibilité
                      _sectionLabel('Planification & prix', icon: Icons.event),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<int>(
                                value: _selectedRestaurantId,
                                decoration: const InputDecoration(
                                  labelText: '🏪 Restaurant *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _restaurants.map((r) {
                                  return DropdownMenuItem<int>(
                                    value: r.id,
                                    child: Text(r.nom),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedRestaurantId = v),
                                validator: (v) => v == null ? 'Veuillez sélectionner un restaurant' : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _dateController,
                                      decoration: const InputDecoration(
                                        labelText: '📅 Date *',
                                        hintText: 'YYYY-MM-DD',
                                        border: OutlineInputBorder(),
                                      ),
                                      readOnly: true,
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (date != null) {
                                          _dateController.text =
                                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'La date est obligatoire';
                                        try {
                                          DateTime.parse(v);
                                          return null;
                                        } catch (_) {
                                          return 'Format de date invalide';
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _prixController,
                                      decoration: const InputDecoration(
                                        labelText: '💰 Prix (€) *',
                                        hintText: '0.00',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Le prix est obligatoire';
                                        final prix = double.tryParse(v);
                                        if (prix == null || prix < 0) return 'Prix invalide';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SwitchListTile(
                                title: const Text('✅ Disponible'),
                                subtitle: const Text('Le menu est disponible à la commande'),
                                value: _disponible,
                                onChanged: (val) => setState(() => _disponible = val),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bloc 3 — Produits & Allergènes
                      _sectionLabel('Composition', icon: Icons.list_alt),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              ProductAllergenSelector(
                                label: '🥬 Produits',
                                selectedItems: _selectedProduits,
                                availableItems: _availableProduits,
                                onChanged: (produits) => setState(() => _selectedProduits = produits),
                                hintText: 'Ajouter des produits...',
                                icon: Icons.eco,
                              ),
                              const SizedBox(height: 12),
                              ProductAllergenSelector(
                                label: '⚠️ Allergènes',
                                selectedItems: _selectedAllergenes,
                                availableItems: _availableAllergenes,
                                onChanged: (allergenes) => setState(() => _selectedAllergenes = allergenes),
                                hintText: 'Ajouter des allergènes...',
                                icon: Icons.warning,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bloc 4 — Image (uniquement en modification)
                      if (isEditing) ...[
                        _sectionLabel('Image', icon: Icons.image_outlined),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ImageUploadWidget(
                              currentImageUrl: _imageUrl,
                              onImageUploaded: (imageUrl) => setState(() => _imageUrl = imageUrl),
                              uploadType: 'menu',
                              itemId: widget.menuToEdit!.id,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Message informatif pour la création
                        Card(
                          elevation: 0,
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Vous pourrez ajouter une image après avoir créé le menu.',
                                    style: TextStyle(color: Colors.blue.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Actions — alignées à gauche + couleurs "plein"
                      Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _isLoading ? null : _saveMenu,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : Text(isEditing ? 'Modifier' : 'Créer'),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
