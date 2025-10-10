// lib/widgets/events/event_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/models/restaurant.dart';
import 'package:vegnbio_front/services/api_service.dart';
import 'package:vegnbio_front/services/events_admin_service.dart';

/// Formulaire de création/modification d'un événement (UI only refactor)
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

    // Pré-remplissage si édition
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
        if (_selectedRestaurantId == null && restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first.id;
        }
      });
    } catch (e) {
      setState(() => _loadingRestaurants = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des restaurants: $e'), backgroundColor: Colors.red),
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
          : _pageShell(
        child: SingleChildScrollView(
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEditing ? 'Modifier l’événement' : 'Créer un événement',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _PublicBadge(isPublic: _isPublic),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    const SizedBox(height: 16),
                    // SECTION : Informations principales
                    _SectionTitle(icon: Icons.info, title: 'Informations principales'),
                    const SizedBox(height: 10),

                    // Restaurant (désactivé si édition)
                    DropdownButtonFormField<int>(
                      value: _selectedRestaurantId,
                      decoration: _filledDecoration(
                        context,
                        label: 'Restaurant *',
                        icon: Icons.restaurant,
                      ),
                      items: _restaurants
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nom)))
                          .toList(),
                      onChanged: isEditing
                          ? null
                          : (value) => setState(() {
                        _selectedRestaurantId = value;
                      }),
                      validator: (v) => v == null ? 'Veuillez sélectionner un restaurant' : null,
                    ),

                    const SizedBox(height: 14),

                    // Titre
                    TextFormField(
                      controller: _titreController,
                      decoration: _filledDecoration(context, label: 'Titre *', icon: Icons.title),
                      validator: (v) => (v == null || v.isEmpty) ? 'Le titre est requis' : null,
                    ),

                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _filledDecoration(context, label: 'Description *', icon: Icons.description),
                      maxLines: 4,
                      validator: (v) => (v == null || v.isEmpty) ? 'La description est requise' : null,
                    ),

                    const SizedBox(height: 22),
                    // SECTION : Planification
                    _SectionTitle(icon: Icons.schedule, title: 'Planification'),
                    const SizedBox(height: 10),

                    // Date & Heure début/fin en grille responsive
                    _ResponsiveGrid(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_formatDate(_startDate)),
                          style: _outlinedButtonStyle(context),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _selectTime(context, true),
                          icon: const Icon(Icons.access_time),
                          label: Text(_startTime.format(context)),
                          style: _outlinedButtonStyle(context),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_formatDate(_endDate)),
                          style: _outlinedButtonStyle(context),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _selectTime(context, false),
                          icon: const Icon(Icons.access_time),
                          label: Text(_endTime.format(context)),
                          style: _outlinedButtonStyle(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    // SECTION : Configuration
                    _SectionTitle(icon: Icons.tune, title: 'Configuration'),
                    const SizedBox(height: 10),

                    // Capacité + Image URL en grille responsive
                    _ResponsiveGrid(
                      children: [
                        TextFormField(
                          controller: _capacityController,
                          decoration: _filledDecoration(
                            context,
                            label: 'Nombre de places *',
                            icon: Icons.people,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Le nombre de places est requis';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Veuillez entrer un nombre valide';
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: _filledDecoration(
                            context,
                            label: 'URL de l\'image (optionnel)',
                            icon: Icons.image,
                            hint: 'events/mon-image.png',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Public / Privé (switch dans un conteneur)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                      ),
                      child: SwitchListTile(
                        title: const Text('Événement public'),
                        subtitle: const Text('Les événements publics sont visibles par tous les utilisateurs'),
                        value: _isPublic,
                        onChanged: (v) => setState(() => _isPublic = v),
                        secondary: Icon(_isPublic ? Icons.public : Icons.lock,
                            color: _isPublic ? Colors.blue : Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions : alignées à droite, compactes et colorées
                    Row(
                      children: [
                        // bouton annuler discret à gauche (optionnel)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Annuler'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submitForm,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Icon(widget.eventToEdit != null ? Icons.save : Icons.add),
                          label: Text(widget.eventToEdit != null ? 'Mettre à jour' : 'Créer'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers (style uniquement) ----------

  /// Conteneur: centre la page et limite la largeur pour le web
  Widget _pageShell({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = 900.0;
        final horizontal = constraints.maxWidth >= 1200
            ? 32.0
            : (constraints.maxWidth >= 900 ? 24.0 : 16.0);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 24),
              child: child,
            ),
          ),
        );
      },
    );
  }

  InputDecoration _filledDecoration(BuildContext context,
      {required String label, required IconData icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  ButtonStyle _outlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      foregroundColor: Colors.grey.shade800,
    );
  }

  // ---------- logique existante (inchangée) ----------

  String _formatDate(DateTime date) {
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    // 👉 Fix Web : retirer le focus courant
    FocusScope.of(context).unfocus();

    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Tu peux omettre ceci si tu as configuré locale dans MaterialApp,
      // mais le laisser ne pose pas de souci :
      locale: const Locale('fr', 'FR'),
      useRootNavigator: true, // 👉 évite des soucis d'arborescences Navigator
      builder: (context, child) {
        // Optionnel : petit thème pour harmoniser
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    // 👉 Fix Web : retirer le focus courant
    FocusScope.of(context).unfocus();

    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      useRootNavigator: true, // 👉 idem
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un restaurant'), backgroundColor: Colors.red),
      );
      return;
    }

    final startDateTime = _combineDateAndTime(_startDate, _startTime);
    final endDateTime = _combineDateAndTime(_endDate, _endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être après la date de début'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.eventToEdit != null;
      if (isEditing) {
        await _eventsService.updateEvent(
          id: widget.eventToEdit!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          capacity: int.parse(_capacityController.text),
          isPublic: _isPublic,
          imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        );
      } else {
        await _eventsService.createEvent(
          restaurantId: _selectedRestaurantId!,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          capacity: int.parse(_capacityController.text),
          isPublic: _isPublic,
          imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Événement mis à jour avec succès' : 'Événement créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// --- Petits widgets UI réutilisés ---

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveGrid({required this.children});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final twoCols = c.maxWidth >= 600;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(children.length, (i) {
          return SizedBox(width: twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth, child: children[i]);
        }),
      );
    });
  }
}

class _PublicBadge extends StatelessWidget {
  final bool isPublic;
  const _PublicBadge({required this.isPublic});
  @override
  Widget build(BuildContext context) {
    final color = isPublic ? Colors.blue : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublic ? Icons.public : Icons.lock, size: 14, color: color),
          const SizedBox(width: 6),
          Text(isPublic ? 'Public' : 'Privé',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
