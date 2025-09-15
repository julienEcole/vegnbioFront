import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/image_upload_widget.dart';
import '../../models/restaurant.dart';

class AdminRestaurantScreen extends ConsumerStatefulWidget {
  final Restaurant? restaurantToEdit;
  
  const AdminRestaurantScreen({super.key, this.restaurantToEdit});

  @override
  ConsumerState<AdminRestaurantScreen> createState() => _AdminRestaurantScreenState();
}

class _AdminRestaurantScreenState extends ConsumerState<AdminRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _quartierController = TextEditingController();
  final _adresseController = TextEditingController();
  
  List<String> _selectedEquipements = [];
  List<Horaire> _horaires = [];
  String? _imageUrl;
  bool _isLoading = false;
  
  // Liste des équipements disponibles
  final List<String> _availableEquipements = [
    'Terrasse', 'Parking', 'Accessible PMR', 'WiFi', 'Climatisation',
    'Chauffage', 'Toilettes', 'Baby-foot', 'Jeux pour enfants'
  ];

  // Liste des jours de la semaine
  final List<String> _joursSemaine = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.restaurantToEdit != null) {
      _initializeFormWithRestaurant(widget.restaurantToEdit!);
    } else {
      _initializeDefaultHoraires();
    }
  }

  void _initializeFormWithRestaurant(Restaurant restaurant) {
    _nomController.text = restaurant.nom;
    _quartierController.text = restaurant.quartier;
    _adresseController.text = restaurant.adresse ?? '';
    _imageUrl = restaurant.imageUrl;
    
    if (restaurant.equipements != null) {
      _selectedEquipements = restaurant.equipements!.map((e) => e.nom).toList();
    }
    
    if (restaurant.horaires != null) {
      _horaires = List.from(restaurant.horaires!);
    } else {
      _initializeDefaultHoraires();
    }
  }

  void _initializeDefaultHoraires() {
    _horaires = _joursSemaine.map((jour) => Horaire(
      id: 0,
      restaurantId: 0,
      jour: jour,
      ouverture: '09:00',
      fermeture: '22:00',
    )).toList();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _quartierController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantToEdit != null ? 'Modifier le restaurant' : 'Nouveau restaurant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.restaurantToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Supprimer le restaurant',
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
              // Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: '🏪 Nom du restaurant *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Quartier
              TextFormField(
                controller: _quartierController,
                decoration: const InputDecoration(
                  labelText: '📍 Quartier *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le quartier est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: '🏠 Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Équipements
              const Text(
                '🔧 Équipements disponibles :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableEquipements.map((equipement) {
                  final isSelected = _selectedEquipements.contains(equipement);
                  return FilterChip(
                    label: Text(equipement),
                    selected: isSelected,
                    selectedColor: Colors.green.shade100,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipements.add(equipement);
                        } else {
                          _selectedEquipements.remove(equipement);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Horaires
              const Text(
                '🕐 Horaires d\'ouverture :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildHorairesSection(),
              const SizedBox(height: 16),
              
              // Image
              const Text(
                '🖼️ Image du restaurant :',
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
                uploadType: 'restaurant',
                itemId: widget.restaurantToEdit?.id ?? 0,
                width: double.infinity,
                height: 200,
              ),
              const SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveRestaurant,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.restaurantToEdit != null ? '✏️ Modifier' : '🏪 Créer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
    );
  }

  Widget _buildHorairesSection() {
    return Column(
      children: _horaires.map((horaire) {
        final index = _horaires.indexOf(horaire);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Jour
                Expanded(
                  flex: 2,
                  child: Text(
                    horaire.jour,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                // Ouverture
                Expanded(
                  child: TextFormField(
                    initialValue: horaire.ouverture,
                    decoration: const InputDecoration(
                      labelText: 'Ouverture',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _horaires[index] = Horaire(
                          id: horaire.id,
                          restaurantId: horaire.restaurantId,
                          jour: horaire.jour,
                          ouverture: value,
                          fermeture: horaire.fermeture,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Fermeture
                Expanded(
                  child: TextFormField(
                    initialValue: horaire.fermeture,
                    decoration: const InputDecoration(
                      labelText: 'Fermeture',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _horaires[index] = Horaire(
                          id: horaire.id,
                          restaurantId: horaire.restaurantId,
                          jour: horaire.jour,
                          ouverture: horaire.ouverture,
                          fermeture: value,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final restaurant = Restaurant(
        id: widget.restaurantToEdit?.id ?? 0,
        nom: _nomController.text.trim(),
        quartier: _quartierController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        imageUrl: _imageUrl,
        images: null, // TODO: Gérer les images multiples
        imagesCount: 0,
        horaires: _horaires,
        equipements: _selectedEquipements.map((nom) => Equipement(
          id: 0,
          nom: nom,
        )).toList(),
      );

      if (widget.restaurantToEdit != null) {
        // TODO: Implémenter la modification via le provider
        // await ref.read(restaurantProvider.notifier).updateRestaurant(restaurant);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant modifié avec succès')),
        );
      } else {
        // TODO: Implémenter la création via le provider
        // await ref.read(restaurantProvider.notifier).createRestaurant(restaurant);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant créé avec succès')),
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
        content: Text('Êtes-vous sûr de vouloir supprimer le restaurant "${widget.restaurantToEdit!.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('❌ Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRestaurant();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('🗑️ Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant() async {
    if (widget.restaurantToEdit == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter la suppression via le provider
      // await ref.read(restaurantProvider.notifier).deleteRestaurant(widget.restaurantToEdit!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant supprimé avec succès')),
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
}
