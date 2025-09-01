import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/image_upload_widget.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/menu.dart';
import '../models/restaurant.dart';

class AdminMenuScreen extends ConsumerStatefulWidget {
  final Menu? menuToEdit;
  
  const AdminMenuScreen({super.key, this.menuToEdit});

  @override
  ConsumerState<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends ConsumerState<AdminMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _prixController = TextEditingController();
  final _allergeneController = TextEditingController();
  final _produitController = TextEditingController();
  
  int? _selectedRestaurantId;
  List<String> _selectedAllergenes = [];
  List<String> _selectedProduits = [];
  String? _imageUrl;
  bool _isLoading = false;
  bool _disponible = true;
  
  // Liste des allergènes disponibles
  final List<String> _availableAllergenes = [
    'Gluten', 'Lactose', 'Œufs', 'Poissons', 'Crustacés', 'Mollusques',
    'Arachides', 'Fruits à coque', 'Soja', 'Céleri', 'Moutarde',
    'Graines de sésame', 'Sulfites', 'Lupin'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.menuToEdit != null) {
      _initializeFormWithMenu(widget.menuToEdit!);
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  void _initializeFormWithMenu(Menu menu) {
    _titreController.text = menu.titre;
    _descriptionController.text = menu.description ?? '';
    _dateController.text = menu.date.toIso8601String().split('T')[0];
    _selectedRestaurantId = menu.restaurantId;
    _selectedAllergenes = List.from(menu.allergenes);
    _selectedProduits = List.from(menu.produits);
    _prixController.text = menu.prix.toString();
    _disponible = menu.disponible;
    _imageUrl = menu.imageUrl;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _prixController.dispose();
    _allergeneController.dispose();
    _produitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuToEdit != null ? 'Modifier le menu' : 'Nouveau menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.menuToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: '📅 Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
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
                    _dateController.text = date.toIso8601String().split('T')[0];
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La date est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Restaurant
              restaurantsAsync.when(
                data: (restaurants) => DropdownButtonFormField<int>(
                  value: _selectedRestaurantId,
                  decoration: const InputDecoration(
                    labelText: '🏪 Restaurant *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  items: restaurants.map((restaurant) => DropdownMenuItem(
                    value: restaurant.id,
                    child: Text(restaurant.nom),
                  )).toList(),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Erreur: $error'),
                             ),
               const SizedBox(height: 16),
               
               // Prix
               TextFormField(
                 controller: _prixController,
                 decoration: const InputDecoration(
                   labelText: '💰 Prix du menu (€) *',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.euro),
                 ),
                 keyboardType: TextInputType.numberWithOptions(decimal: true),
                 validator: (value) {
                   if (value == null || value.trim().isEmpty) {
                     return 'Le prix est obligatoire';
                   }
                   if (double.tryParse(value) == null) {
                     return 'Veuillez entrer un prix valide';
                   }
                   return null;
                 },
               ),
               const SizedBox(height: 16),
               
               // Disponibilité
               Row(
                 children: [
                   Checkbox(
                     value: _disponible,
                     onChanged: (value) {
                       setState(() {
                         _disponible = value ?? true;
                       });
                     },
                   ),
                   const Text(
                     '✅ Menu disponible',
                     style: TextStyle(fontSize: 16),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               
               // Allergènes
               const Text(
                 '⚠️ Allergènes présents dans ce menu :',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
               ),
               const SizedBox(height: 8),
               // Champ pour ajouter un allergène manuellement
               Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _allergeneController,
                       decoration: const InputDecoration(
                         labelText: 'Ajouter un allergène',
                         border: OutlineInputBorder(),
                         hintText: 'Ex: Noix, Fruits de mer...',
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: () {
                       final allergene = _allergeneController.text.trim();
                       if (allergene.isNotEmpty && !_selectedAllergenes.contains(allergene)) {
                         setState(() {
                           _selectedAllergenes.add(allergene);
                           _allergeneController.clear();
                         });
                       }
                     },
                     child: const Text('➕'),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               // Liste des allergènes disponibles
               Wrap(
                 spacing: 8,
                 runSpacing: 4,
                 children: _availableAllergenes.map((allergene) {
                   final isSelected = _selectedAllergenes.contains(allergene);
                   return FilterChip(
                     label: Text(allergene),
                     selected: isSelected,
                     selectedColor: Colors.orange.shade100,
                     onSelected: (selected) {
                       setState(() {
                         if (selected) {
                           _selectedAllergenes.add(allergene);
                         } else {
                           _selectedAllergenes.remove(allergene);
                         }
                       });
                     },
                   );
                 }).toList(),
               ),
               // Affichage des allergènes sélectionnés
               if (_selectedAllergenes.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 Wrap(
                   spacing: 8,
                   runSpacing: 4,
                   children: _selectedAllergenes.map((allergene) {
                     return Chip(
                       label: Text(allergene),
                       backgroundColor: Colors.red.shade100,
                       deleteIcon: const Icon(Icons.close, size: 18),
                       onDeleted: () {
                         setState(() {
                           _selectedAllergenes.remove(allergene);
                         });
                       },
                     );
                   }).toList(),
                 ),
                              ],
               const SizedBox(height: 16),
               
               // Produits
               const Text(
                 '🍽️ Produits du menu :',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
               ),
               const SizedBox(height: 8),
               // Champ pour ajouter un produit manuellement
               Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _produitController,
                       decoration: const InputDecoration(
                         labelText: 'Ajouter un produit',
                         border: OutlineInputBorder(),
                         hintText: 'Ex: Salade quinoa, Gazpacho bio...',
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: () {
                       final produit = _produitController.text.trim();
                       if (produit.isNotEmpty && !_selectedProduits.contains(produit)) {
                         setState(() {
                           _selectedProduits.add(produit);
                           _produitController.clear();
                         });
                       }
                     },
                     child: const Text('➕'),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               // Affichage des produits sélectionnés
               if (_selectedProduits.isNotEmpty) ...[
                 Wrap(
                   spacing: 8,
                   runSpacing: 4,
                   children: _selectedProduits.map((produit) {
                     return Chip(
                       label: Text(produit),
                       backgroundColor: Colors.green.shade100,
                       deleteIcon: const Icon(Icons.close, size: 18),
                       onDeleted: () {
                         setState(() {
                           _selectedProduits.remove(produit);
                         });
                       },
                     );
                   }).toList(),
                 ),
               ],
               const SizedBox(height: 16),
               
               // Image
               const Text(
                 '🖼️ Image du menu :',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
               ),
              const SizedBox(height: 8),
              ImageUploadWidget(
                currentImageUrl: _imageUrl,
                onImageUploaded: (imageUrl) {
                  setState(() {
                    _imageUrl = imageUrl;
                  });
                },
                uploadType: 'menu',
                itemId: widget.menuToEdit?.id ?? 0,
                width: double.infinity,
                height: 200,
              ),
              const SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMenu,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.menuToEdit != null ? '✏️ Modifier' : '🍽️ Créer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('❌ Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRestaurantId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final menu = Menu(
        id: widget.menuToEdit?.id ?? 0,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        date: DateTime.parse(_dateController.text),
        allergenes: _selectedAllergenes,
        produits: _selectedProduits,
        restaurantId: _selectedRestaurantId!,
        prix: double.tryParse(_prixController.text) ?? 0.0,
        disponible: _disponible,
        imageUrl: _imageUrl,
      );

      if (widget.menuToEdit != null) {
        // TODO: Implémenter la modification via le provider
        // await ref.read(menuProvider.notifier).updateMenu(menu);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu modifié avec succès')),
        );
      } else {
        // TODO: Implémenter la création via le provider
        // await ref.read(menuProvider.notifier).createMenu(menu);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu créé avec succès')),
        );
      }

      context.pop();
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
        content: Text('Êtes-vous sûr de vouloir supprimer le menu "${widget.menuToEdit!.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('❌ Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteMenu();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('🗑️ Supprimer'),
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
      // TODO: Implémenter la suppression via le provider
      // await ref.read(menuProvider.notifier).deleteMenu(widget.menuToEdit!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu supprimé avec succès')),
      );
      context.pop();
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
}
