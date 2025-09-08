import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/image_upload_widget.dart';
import '../../services/api_service.dart';

class EditRestaurantScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  
  const EditRestaurantScreen({super.key, required this.restaurant});

  @override
  ConsumerState<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends ConsumerState<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _addressController;
  late List<Equipement> _selectedEquipments;
  late Map<String, TimeOfDay> _openingHours;
  String? _imageUrl;
  bool _isLoading = false;

  final List<Equipement> _availableEquipments = [
    Equipement(id: 1, nom: 'Wi-Fi très haut débit'),
    Equipement(id: 2, nom: 'Imprimante'),
    Equipement(id: 3, nom: 'Plateaux membres'),
    Equipement(id: 4, nom: 'Plateaux repas livrables'),
    Equipement(id: 5, nom: 'Salles de réunion'),
    Equipement(id: 6, nom: 'Conférences et animations'),
  ];

  final List<String> _daysOfWeek = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 
    'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant.nom);
    _neighborhoodController = TextEditingController(text: widget.restaurant.quartier);
    _addressController = TextEditingController(text: widget.restaurant.adresse);
    _selectedEquipments = []; // TODO: Récupérer depuis le restaurant
    _imageUrl = widget.restaurant.imageUrl;
    
    // Initialiser les horaires par défaut
    _openingHours = {};
    for (String day in _daysOfWeek) {
      _openingHours[day] = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier : ${widget.restaurant.nom}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveRestaurant,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nom
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '🏪 Nom du restaurant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quartier
            TextFormField(
              controller: _neighborhoodController,
              decoration: const InputDecoration(
                labelText: '📍 Quartier',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le quartier est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '🏠 Adresse complète',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Équipements
            const Text(
              '🔧 Équipements disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableEquipments.map((equipment) {
                final isSelected = _selectedEquipments.contains(equipment);
                return FilterChip(
                  label: Text(equipment.nom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEquipments.add(equipment);
                      } else {
                        _selectedEquipments.remove(equipment);
                      }
                    });
                  },
                  selectedColor: Colors.green.withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Horaires d'ouverture
            const Text(
              '🕐 Horaires d\'ouverture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._daysOfWeek.map((day) => _buildTimeRow(day)),
            const SizedBox(height: 16),

            // Image
            const Text(
              '🖼️ Image du restaurant',
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
              uploadType: 'restaurant',
              itemId: widget.restaurant.id,
              width: double.infinity,
              height: 200,
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveRestaurant,
                    icon: const Icon(Icons.save),
                    label: const Text('💾 Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

  Widget _buildTimeRow(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectTime(context, day),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  _openingHours[day]?.format(context) ?? '09:00',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openingHours[day] ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _openingHours[day] = picked;
      });
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      
      // Créer l'objet Restaurant mis à jour
      final updatedRestaurant = Restaurant(
        id: widget.restaurant.id,
        nom: _nameController.text.trim(),
        quartier: _neighborhoodController.text.trim(),
        adresse: _addressController.text.trim(),
        equipements: _selectedEquipments,
        horaires: _openingHours.entries.map((entry) => 
          Horaire(
            id: 0, // ID temporaire
            restaurantId: widget.restaurant.id,
            jour: entry.key,
            ouverture: '${entry.value.hour.toString().padLeft(2, '0')}:${entry.value.minute.toString().padLeft(2, '0')}',
            fermeture: '18:00', // Heure de fermeture par défaut
          )
        ).toList(),
        imageUrl: _imageUrl,
      );
      
      // Appeler l'API pour mettre à jour
      final result = await apiService.updateRestaurant(
        id: updatedRestaurant.id,
        nom: updatedRestaurant.nom,
        quartier: updatedRestaurant.quartier,
        adresse: updatedRestaurant.adresse,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rafraîchir les providers
        ref.invalidate(restaurantProvider(updatedRestaurant.id));
        ref.invalidate(restaurantsProvider);
        
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
