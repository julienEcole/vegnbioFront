import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/product_allergen_selector.dart';
import '../../models/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';

/// Écran de formulaire pour créer ou modifier un menu
/// Utilisé par les restaurateurs, fournisseurs et admins pour gérer les menus
class MenuFormScreen extends ConsumerStatefulWidget {
  final Menu? menuToEdit;
  
  const MenuFormScreen({super.key, this.menuToEdit});

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
      
      // Charger les restaurants
      final restaurants = await apiService.getRestaurants();
      
      // Charger les menus existants pour récupérer les allergènes et produits
      final menus = await apiService.getMenus();
      
      setState(() {
        _restaurants = restaurants;
        
        // Extraire tous les allergènes et produits uniques des menus existants
        final allAllergenes = <String>{};
        final allProduits = <String>{};
        
        for (final menu in menus) {
          allAllergenes.addAll(menu.allergenes);
          allProduits.addAll(menu.produits);
        }
        
        // Ajouter les allergènes et produits par défaut
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
      });
    } catch (e) {
      print('Erreur lors du chargement des données initiales: $e');
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
    _dateController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _prixController.text = '0.00';
    
    // Sélectionner le premier restaurant par défaut
    if (_restaurants.isNotEmpty) {
      _selectedRestaurantId = _restaurants.first.id;
    }
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

    setState(() {
      _isLoading = true;
    });

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
          imageUrl: _imageUrl,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu créé avec succès')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      await apiService.deleteMenu(widget.menuToEdit!.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu "${widget.menuToEdit!.titre}" supprimé avec succès')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuToEdit != null ? 'Modifier le menu' : 'Nouveau menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.menuToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Supprimer le menu',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: '🍽️ Titre du menu *',
                  hintText: 'Ex: Menu Végétarien Bio',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '📝 Description',
                  hintText: 'Description du menu...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Restaurant
              DropdownButtonFormField<int>(
                value: _selectedRestaurantId,
                decoration: const InputDecoration(
                  labelText: '🏪 Restaurant *',
                  border: OutlineInputBorder(),
                ),
                items: _restaurants.map((restaurant) {
                  return DropdownMenuItem<int>(
                    value: restaurant.id,
                    child: Text(restaurant.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRestaurantId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un restaurant';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              TextFormField(
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
                    _dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La date est obligatoire';
                  }
                  try {
                    DateTime.parse(value);
                    return null;
                  } catch (e) {
                    return 'Format de date invalide';
                  }
                },
              ),
              const SizedBox(height: 16),

              // Prix
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(
                  labelText: '💰 Prix (€) *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prix est obligatoire';
                  }
                  final prix = double.tryParse(value);
                  if (prix == null || prix < 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Produits
              ProductAllergenSelector(
                label: '🥬 Produits',
                selectedItems: _selectedProduits,
                availableItems: _availableProduits,
                onChanged: (produits) {
                  setState(() {
                    _selectedProduits = produits;
                  });
                },
                hintText: 'Ajouter des produits...',
                icon: Icons.eco,
              ),
              const SizedBox(height: 16),

              // Allergènes
              ProductAllergenSelector(
                label: '⚠️ Allergènes',
                selectedItems: _selectedAllergenes,
                availableItems: _availableAllergenes,
                onChanged: (allergenes) {
                  setState(() {
                    _selectedAllergenes = allergenes;
                  });
                },
                hintText: 'Ajouter des allergènes...',
                icon: Icons.warning,
              ),
              const SizedBox(height: 16),

              // Disponibilité
              SwitchListTile(
                title: const Text('✅ Disponible'),
                subtitle: const Text('Le menu est disponible à la commande'),
                value: _disponible,
                onChanged: (value) {
                  setState(() {
                    _disponible = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Image
              ImageUploadWidget(
                currentImageUrl: _imageUrl,
                onImageUploaded: (imageUrl) {
                  setState(() {
                    _imageUrl = imageUrl;
                  });
                },
                uploadType: 'menu',
                itemId: widget.menuToEdit?.id ?? 0,
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMenu,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.menuToEdit != null ? 'Modifier' : 'Créer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}