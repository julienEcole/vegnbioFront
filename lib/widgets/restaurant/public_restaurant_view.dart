import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import 'restaurant_images_widget.dart';
import 'restaurant_menus_sheet.dart';
import '../cart/cart_widgets.dart';

/// Vue publique des restaurants
class PublicRestaurantView extends ConsumerWidget {
  final int? highlightRestaurantId;

  const PublicRestaurantView({super.key, this.highlightRestaurantId});

  void _handleLogin(BuildContext context) => context.go('/profil?view=login');
  void _handleLogout(WidgetRef ref) => ref.read(authProvider.notifier).logout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ElevatedButton.icon(
            onPressed: authState.isAuthenticated ? () => _handleLogout(ref) : () => _handleLogin(context),
            icon: Icon(authState.isAuthenticated ? Icons.logout : Icons.login),
            label: Text(authState.isAuthenticated ? 'Se déconnecter' : 'Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: authState.isAuthenticated ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!authState.isAuthenticated)
            _InfoBanner(
              title: 'Vue publique des restaurants',
              subtitle: 'Connectez-vous pour accéder aux fonctionnalités complètes',
            ),
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) => _centeredShell(
                child: _RestaurantsList(
                  restaurants: restaurants,
                  highlightRestaurantId: highlightRestaurantId,
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LoadError(error: error, onRetry: () => ref.invalidate(restaurantsProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: const CartFloatingButton(),
    );
  }

  /// Conteneur centré avec largeur max sur web + padding latéral
  Widget _centeredShell({required Widget child}) {
    final maxWidth = kIsWeb ? 1100.0 : double.infinity;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 8, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}

class _RestaurantsList extends StatelessWidget {
  final List<Restaurant> restaurants;
  final int? highlightRestaurantId;
  const _RestaurantsList({required this.restaurants, this.highlightRestaurantId});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun restaurant disponible', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final r = restaurants[index];
        final isHighlighted = highlightRestaurantId != null && r.id == highlightRestaurantId;

        return Card(
          elevation: isHighlighted ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isHighlighted
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
                : BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // images
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 220,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
                      return SizedBox(
                        width: w,
                        height: 220,
                        child: RestaurantImagesWidget(
                          images: r.allImages,
                          width: w,                // <-- passe une width FINIE à ton widget
                          height: 220,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          fit: BoxFit.cover,
                          showMultipleImages: true,
                          enableHorizontalScroll: true,
                        ),
                      );
                    },
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.nom,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
                        ),
                        child: Text('Sélectionné',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                      ),
                  ],
                ),
              ),

              // quartier / adresse
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${r.quartier} • ${r.adresse ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // horaires + équipements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _HorairesEquipementsSection(
                  horaires: r.horaires ?? const [],
                  equipements: r.equipements ?? const [],
                ),
              ),

              const SizedBox(height: 12),

              // CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // même route que chez toi
                      context.go('/restaurants/${r.id}', extra: {'name': r.nom});
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Voir les menus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HorairesEquipementsSection extends StatelessWidget {
  final List<dynamic> horaires;
  final List<dynamic> equipements;
  const _HorairesEquipementsSection({required this.horaires, required this.equipements});

  static const _joursOrdre = {
    'Lundi': 1, 'Mardi': 2, 'Mercredi': 3, 'Jeudi': 4, 'Vendredi': 5, 'Samedi': 6, 'Dimanche': 7
  };

  // --- Helpers robustes: Map OU objet (Horaire / Equipement) ---
  String _readJour(dynamic h) {
    if (h is Map) return (h['jour'] as String?) ?? '';
    final v = (h as dynamic).jour; // champ sur l'objet Horaire
    return v is String ? v : (v?.toString() ?? '');
  }

  String _readOuverture(dynamic h) {
    if (h is Map) return h['ouverture']?.toString() ?? '';
    final v = (h as dynamic).ouverture;
    return v?.toString() ?? '';
  }

  String _readFermeture(dynamic h) {
    if (h is Map) return h['fermeture']?.toString() ?? '';
    final v = (h as dynamic).fermeture;
    return v?.toString() ?? '';
  }

  String _readEquipementNom(dynamic e) {
    if (e is Map) return (e['nom'] as String?) ?? '';
    final v = (e as dynamic).nom;
    return v?.toString() ?? '';
  }

  String _hhmm(String s) {
    if (s.isEmpty) return '--:--';
    // "09:00:00" -> "09:00"
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  String _todayFrench() {
    switch (DateTime.now().weekday) {
      case 1: return 'Lundi';
      case 2: return 'Mardi';
      case 3: return 'Mercredi';
      case 4: return 'Jeudi';
      case 5: return 'Vendredi';
      case 6: return 'Samedi';
      case 7: return 'Dimanche';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...horaires]..sort((a, b) {
      final ja = _readJour(a);
      final jb = _readJour(b);
      return (_joursOrdre[ja] ?? 99).compareTo((_joursOrdre[jb] ?? 99));
    });

    final todayName = _todayFrench();
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HORAIRES ---
        Text('Horaires', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
          ),
          child: Column(
            children: sorted.map((h) {
              final jour = _readJour(h);
              final open = _hhmm(_readOuverture(h));
              final close = _hhmm(_readFermeture(h));
              final isToday = jour.toLowerCase() == todayName.toLowerCase();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday ? accent.withOpacity(0.06) : null,
                  borderRadius: sorted.first == h
                      ? const BorderRadius.vertical(top: Radius.circular(12))
                      : (sorted.last == h
                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                      : BorderRadius.zero),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(jour, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          )),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: accent.withOpacity(0.3)),
                              ),
                              child: Text('Aujourd’hui',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text('$open – $close',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // --- ÉQUIPEMENTS ---
        Text('Équipements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (equipements.isEmpty)
          Text('—', style: Theme.of(context).textTheme.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: equipements.map((e) {
              final nom = _readEquipementNom(e);
              return Chip(
                label: Text(nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                shape: StadiumBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}


class _InfoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  const _InfoBanner({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erreur lors du chargement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error.toString(), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
