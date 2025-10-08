// Placez ce fichier dans : lib/widgets/events/event_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/models/restaurant.dart';
import 'package:vegnbio_front/services/api_service.dart';
import 'package:vegnbio_front/services/events_admin_service.dart';

/// Formulaire de création/modification d'un événement
class EventFormScreen extends ConsumerStatefulWidget {
  final Event? eventToEdit;

  const EventFormScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final EventsAdminService _eventsService = EventsAdminService();

  // Contrôleurs
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Variables d'état
  List<Restaurant> _restaurants = [];
  int? _selectedRestaurantId;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);
  bool _isPublic = true;
  bool _isLoading = false;
  bool _loadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();

    // Si on édite un événement, remplir les champs
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titreController.text = event.titre;
      _descriptionController.text = event.description;
      _capacityController.text = event.capacity.toString();
      _imageUrlController.text = event.imageUrl ?? '';
      _selectedRestaurantId = event.restaurantId;

      _startDate = event.startAt;
      _startTime = TimeOfDay(hour: event.startAt.hour, minute: event.startAt.minute);
      _endDate = event.endAt;
      _endTime = TimeOfDay(hour: event.endAt.hour, minute: event.endAt.minute);
      _isPublic = event.isPublic;
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _apiService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _loadingRestaurants = false;

        // Sélectionner le premier restaurant par défaut si pas d'édition
        if (_selectedRestaurantId == null && restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _loadingRestaurants = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des restaurants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'événement' : 'Créer un événement'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loadingRestaurants
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant
              DropdownButtonFormField<int>(
                value: _selectedRestaurantId,
                decoration: const InputDecoration(
                  labelText: 'Restaurant *',
                  prefixIcon: Icon(Icons.restaurant),
                  border: OutlineInputBorder(),
                ),
                items: _restaurants.map((restaurant) {
                  return DropdownMenuItem(
                    value: restaurant.id,
                    child: Text(restaurant.nom),
                  );
                }).toList(),
                onChanged: isEditing ? null : (value) {
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

              // Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date et heure de début
              Text(
                'Date et heure de début *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDate(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: const Icon(Icons.access_time),
                      label: Text(_startTime.format(context)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date et heure de fin
              Text(
                'Date et heure de fin *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDate(_endDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, false),
                      icon: const Icon(Icons.access_time),
                      label: Text(_endTime.format(context)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Capacité
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places *',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nombre de places est requis';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // URL de l'image
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de l\'image (optionnel)',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                  hintText: 'events/mon-image.png',
                ),
              ),

              const SizedBox(height: 16),

              // Visibilité publique
              SwitchListTile(
                title: const Text('Événement public'),
                subtitle: const Text(
                  'Les événements publics sont visibles par tous les utilisateurs',
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? Colors.blue : Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        isEditing ? 'Mettre à jour' : 'Créer',
                        style: const TextStyle(fontSize: 16),
                      ),
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

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ajuster la date de fin si nécessaire
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startDateTime = _combineDateAndTime(_startDate, _startTime);
    final endDateTime = _combineDateAndTime(_endDate, _endTime);

    // Validation des dates
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.eventToEdit != null;

      if (isEditing) {
        // Mise à jour
        await _eventsService.updateEvent(
          id: widget.eventToEdit!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          capacity: int.parse(_capacityController.text),
          isPublic: _isPublic,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
        );
      } else {
        // Création
        await _eventsService.createEvent(
          restaurantId: _selectedRestaurantId!,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          capacity: int.parse(_capacityController.text),
          isPublic: _isPublic,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Événement mis à jour avec succès'
                  : 'Événement créé avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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