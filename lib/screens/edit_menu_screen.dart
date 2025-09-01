import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/menu.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/image_upload_widget.dart';
import '../services/api_service.dart';

class EditMenuScreen extends ConsumerStatefulWidget {
  final Menu menu;
  
  const EditMenuScreen({super.key, required this.menu});

  @override
  ConsumerState<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends ConsumerState<EditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;
  late TextEditingController _allergeneController;
  late TextEditingController _produitController;
  late DateTime _selectedDate;
  late int _selectedRestaurantId;
  late List<String> _selectedAllergenes;
  late List<String> _selectedProduits;
  late double _prix;
  late bool _disponible;
  String? _imageUrl;
  bool _isLoading = false;

  final List<String> _availableAllergenes = [
    'gluten', 'lactose', 'œufs', 'poissons', 'crustacés', 
    'mollusques', 'arachides', 'fruits à coque', 'soja', 
    'céleri', 'moutarde', 'graines de sésame', 'sulfites', 
    'lupin', 'anhydride sulfureux'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menu.titre);
    _descriptionController = TextEditingController(text: widget.menu.description);
    _prixController = TextEditingController(text: widget.menu.prix.toString());
    _allergeneController = TextEditingController();
    _produitController = TextEditingController();
    _selectedDate = widget.menu.date;
    _selectedRestaurantId = widget.menu.restaurantId;
    _selectedAllergenes = List.from(widget.menu.allergenes);
    _selectedProduits = List.from(widget.menu.produits);
    _prix = widget.menu.prix;
    _disponible = widget.menu.disponible;
    _imageUrl = widget.menu.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
        title: Text('Modifier le menu : ${widget.menu.titre}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveMenu,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: restaurantsAsync.when(
        data: (restaurants) => _buildForm(restaurants),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildForm(List<Restaurant> restaurants) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '🍽️ Titre du menu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est requis';
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '📅 Date de disponibilité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Restaurant
            DropdownButtonFormField<int>(
              value: _selectedRestaurantId,
              decoration: const InputDecoration(
                labelText: '🏪 Restaurant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              items: restaurants.map((restaurant) {
                return DropdownMenuItem(
                  value: restaurant.id,
                  child: Text(restaurant.nom),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRestaurantId = value!;
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
 
             // Prix
             TextFormField(
               controller: _prixController,
               decoration: const InputDecoration(
                 labelText: '💰 Prix du menu (€)',
                 border: OutlineInputBorder(),
                 prefixIcon: Icon(Icons.euro),
               ),
               keyboardType: TextInputType.numberWithOptions(decimal: true),
               validator: (value) {
                 if (value == null || value.trim().isEmpty) {
                   return 'Le prix est requis';
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
               '⚠️ Allergènes présents',
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
               children: _availableAllergenes.map((allergene) {
                 final isSelected = _selectedAllergenes.contains(allergene);
                 return FilterChip(
                   label: Text(allergene),
                   selected: isSelected,
                   onSelected: (selected) {
                     setState(() {
                       if (selected) {
                         _selectedAllergenes.add(allergene);
                       } else {
                         _selectedAllergenes.remove(allergene);
                       }
                     });
                   },
                   selectedColor: Colors.orange.withOpacity(0.3),
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
               '🍽️ Produits du menu',
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
               '🖼️ Image du menu',
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              itemId: widget.menu.id,
              width: double.infinity,
              height: 200,
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveMenu,
                    icon: const Icon(Icons.save),
                    label: const Text('💾 Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => context.pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('❌ Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      
             // Créer l'objet Menu mis à jour
       final updatedMenu = Menu(
         id: widget.menu.id,
         titre: _titleController.text.trim(),
         description: _descriptionController.text.trim(),
         date: _selectedDate,
         allergenes: _selectedAllergenes,
         produits: _selectedProduits,
         restaurantId: _selectedRestaurantId,
         prix: double.tryParse(_prixController.text) ?? _prix,
         disponible: _disponible,
         imageUrl: _imageUrl,
       );
      
      // Appeler l'API pour mettre à jour
      final result = await apiService.updateMenu(
        id: updatedMenu.id,
        titre: updatedMenu.titre,
        description: updatedMenu.description,
        date: updatedMenu.date,
        restaurantId: updatedMenu.restaurantId,
        allergenes: updatedMenu.allergenes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rafraîchir les providers
        ref.invalidate(menuProvider(updatedMenu.id));
        ref.invalidate(filteredMenusProvider);
        
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
