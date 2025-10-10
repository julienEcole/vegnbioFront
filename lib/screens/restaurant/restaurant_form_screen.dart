import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/restaurant/restaurant_images_manager.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';

/// Écran de formulaire pour créer ou modifier un restaurant
/// (UI améliorée uniquement – logique inchangée)
class RestaurantFormScreen extends ConsumerStatefulWidget {
  final Restaurant? restaurantToEdit;

  const RestaurantFormScreen({super.key, this.restaurantToEdit});

  @override
  ConsumerState<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends ConsumerState<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _quartierController = TextEditingController();
  final _adresseController = TextEditingController();

  List<int> _selectedEquipementIds = [];
  List<Equipement> _availableEquipements = [];
  List<Horaire> _horaires = [];
  bool _isLoading = false;
  bool _isLoadingEquipements = true;

  // Jours de la semaine
  final List<String> _joursSemaine = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipements();
    if (widget.restaurantToEdit != null) {
      _initializeFormWithRestaurant(widget.restaurantToEdit!);
    } else {
      _initializeDefaultHoraires();
    }
  }

  Future<void> _loadEquipements() async {
    try {
      final apiService = ApiService();
      final equipements = await apiService.getEquipements();
      setState(() {
        _availableEquipements = equipements;
        _isLoadingEquipements = false;
      });
    } catch (e) {
      setState(() => _isLoadingEquipements = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des équipements: $e')),
        );
      }
    }
  }

  void _initializeFormWithRestaurant(Restaurant restaurant) {
    _nomController.text = restaurant.nom;
    _quartierController.text = restaurant.quartier;
    _adresseController.text = restaurant.adresse ?? '';

    if (restaurant.equipements != null) {
      _selectedEquipementIds = restaurant.equipements!.map((e) => e.id).toList();
    }

    if (restaurant.horaires != null) {
      _horaires = List.from(restaurant.horaires!);
    } else {
      _initializeDefaultHoraires();
    }
  }

  void _initializeDefaultHoraires() {
    _horaires = _joursSemaine
        .map((jour) => Horaire(
      id: 0,
      restaurantId: 0,
      jour: jour,
      ouverture: '09:00',
      fermeture: '22:00',
    ))
        .toList();
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
    // ——— Shell centré + largeur max (évite le full-width sur le web)
    Widget wrapShell(Widget child) {
      const maxContentWidth = 980.0; // ajuste si tu veux
      final width = MediaQuery.of(context).size.width;
      final hPad = width >= 1200 ? 32.0 : (width >= 900 ? 24.0 : 16.0);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restaurantToEdit != null ? 'Modifier le restaurant' : 'Nouveau restaurant',
        ),
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
      body: wrapShell(
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ——— SECTION : infos principales
                _SectionCard(
                  title: 'Informations générales',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: '🏪 Nom du restaurant *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quartierController,
                        decoration: const InputDecoration(
                          labelText: '📍 Quartier *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Le quartier est obligatoire' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adresseController,
                        decoration: const InputDecoration(
                          labelText: '🏠 Adresse',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // ——— SECTION : équipements
                _SectionCard(
                  title: 'Équipements disponibles',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _isLoadingEquipements
                          ? [const CircularProgressIndicator()]
                          : _availableEquipements.map((equipement) {
                        final selected = _selectedEquipementIds.contains(equipement.id);
                        return FilterChip(
                          label: Text(equipement.nom),
                          selected: selected,
                          selectedColor: Colors.green.withOpacity(.15),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedEquipementIds.add(equipement.id);
                              } else {
                                _selectedEquipementIds.remove(equipement.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ——— SECTION : horaires
                _SectionCard(
                  title: 'Horaires d\'ouverture',
                  child: _buildHorairesSection(),
                ),

                // ——— SECTION : images (gestion multiple)
                _SectionCard(
                  title: 'Images du restaurant',
                  child: RestaurantImagesManager(
                    restaurantId: widget.restaurantToEdit?.id ?? 0,
                    initialImages: widget.restaurantToEdit?.images,
                  ),
                ),

                // ——— ACTIONS : alignées à gauche, boutons en plein
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveRestaurant,
                        icon: _isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.save),
                        label: Text(widget.restaurantToEdit != null ? 'Enregistrer' : 'Créer'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorairesSection() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: _horaires.map((horaire) {
        final index = _horaires.indexOf(horaire);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.25)),
          ),
          child: Row(
            children: [
              // Jour
              SizedBox(
                width: 110,
                child: Text(
                  horaire.jour,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Ouverture
              Expanded(
                child: TextFormField(
                  initialValue: horaire.ouverture,
                  decoration: const InputDecoration(
                    labelText: 'Ouverture',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _horaires[index] = Horaire(
                        id: horaire.id,
                        restaurantId: horaire.restaurantId,
                        jour: horaire.jour,
                        ouverture: v,
                        fermeture: horaire.fermeture,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Fermeture
              Expanded(
                child: TextFormField(
                  initialValue: horaire.fermeture,
                  decoration: const InputDecoration(
                    labelText: 'Fermeture',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _horaires[index] = Horaire(
                        id: horaire.id,
                        restaurantId: horaire.restaurantId,
                        jour: horaire.jour,
                        ouverture: horaire.ouverture,
                        fermeture: v,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      // Préparer les horaires au bon format
      final horairesData = _horaires.map((h) => {
        'jour': h.jour,
        'ouverture': h.ouverture,
        'fermeture': h.fermeture,
      }).toList();

      if (widget.restaurantToEdit != null) {
        await apiService.updateRestaurant(
          id: widget.restaurantToEdit!.id,
          nom: _nomController.text.trim(),
          quartier: _quartierController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          equipementIds: _selectedEquipementIds,
          horaires: horairesData,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant modifié avec succès')),
        );
      } else {
        await apiService.createRestaurant(
          nom: _nomController.text.trim(),
          quartier: _quartierController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          equipementIds: _selectedEquipementIds,
          horaires: horairesData,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant créé avec succès')),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le restaurant "${widget.restaurantToEdit!.nom}" ?',
        ),
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

    setState(() => _isLoading = true);
    try {
      // TODO: appel suppression réel si besoin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant supprimé avec succès')),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Petite carte de section, pour structurer le formulaire
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w800);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
