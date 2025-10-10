import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/menu.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';

import 'package:vegnbio_front/widgets/cart/cart_floating_button.dart';

/// Page listant les menus d'un restaurant avec recherche + filtres + détail produits.
class RestaurantMenusScreen extends ConsumerStatefulWidget {
  final int restaurantId;
  final String restaurantName; // passe-le via navigation pour l’affichage

  const RestaurantMenusScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<RestaurantMenusScreen> createState() => _RestaurantMenusScreenState();
}

class _RestaurantMenusScreenState extends ConsumerState<RestaurantMenusScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  RangeValues? _priceRange; // min/max dynamiques après chargement
  bool _hideAllergen = false;
  final Set<String> _excludedAllergens = {}; // ex: "gluten","lactose"...

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menusAsync = ref.watch(menusByRestaurantProvider(widget.restaurantId));
    final cartState = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: menusAsync.when(
        data: (menus) {
          // init dynamique des bornes du slider
          final prices = menus.map((m) => m.prix).whereType<double>().toList()..sort();
          final minPrice = prices.isEmpty ? 0.0 : prices.first.floorToDouble();
          final maxPrice = prices.isEmpty ? 0.0 : prices.last.ceilToDouble();
          final currentRange = _priceRange ?? RangeValues(minPrice, maxPrice);

          // filtre texte
          final q = _searchCtrl.text.trim().toLowerCase();
          Iterable<Menu> filtered = menus.where((m) {
            final inText = q.isEmpty ||
                m.titre.toLowerCase().contains(q) ||
                (m.description ?? '').toLowerCase().contains(q);
            final inPrice = (m.prix >= currentRange.start && m.prix <= currentRange.end);
            final okAllergen = !_hideAllergen ||
                m.allergenes.isEmpty ||
                m.allergenes.every((a) => !_excludedAllergens.contains(a.toLowerCase()));
            return inText && inPrice && okAllergen;
          });

          final filteredList = filtered.toList();

          return Column(
            children: [
              _FiltersBar(
                searchCtrl: _searchCtrl,
                onSearchChanged: () => setState(() {}),
                minPrice: minPrice,
                maxPrice: maxPrice,
                priceRange: currentRange,
                onPriceChanged: (r) => setState(() => _priceRange = r),
                allergenValues: _collectAllergens(menus),
                hideAllergen: _hideAllergen,
                onHideAllergenChanged: (v) => setState(() => _hideAllergen = v),
                excludedAllergens: _excludedAllergens,
                onToggleExclude: (a) => setState(() {
                  final key = a.toLowerCase();
                  if (_excludedAllergens.contains(key)) {
                    _excludedAllergens.remove(key);
                  } else {
                    _excludedAllergens.add(key);
                  }
                }),
                onClearFilters: () => setState(() {
                  _searchCtrl.clear();
                  _priceRange = null;
                  _hideAllergen = false;
                  _excludedAllergens.clear();
                }),
              ),
              const Divider(height: 1),
              Expanded(
                child: filteredList.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final menu = filteredList[i];
                    final quantity = cartState.quantityFor(menuId: menu.id, restaurantId: widget.restaurantId);
                    return _MenuCard(
                      menu: menu,
                      quantity: quantity,
                      onAdd: () => cart.addItem(menu, widget.restaurantId, quantite: 1),
                      onInc: () => cart.updateItemQuantity(menu, widget.restaurantId, quantity + 1),
                      onDec: () => cart.updateItemQuantity(menu, widget.restaurantId, quantity - 1),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorState(error: e.toString(), onRetry: () {
          ref.invalidate(menusByRestaurantProvider(widget.restaurantId));
        }),
      ),
      // Garde ton bouton panier si tu le souhaites
      floatingActionButton: const CartFloatingButton(),
    );
  }

  /// Agrège la liste d'allergènes possibles sur l'ensemble des menus
  List<String> _collectAllergens(List<Menu> menus) {
    final s = <String>{};
    for (final m in menus) {
      for (final a in m.allergenes) {
        if (a.trim().isNotEmpty) s.add(a);
      }
    }
    final list = s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}

/// Barre de recherche + filtres
class _FiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onSearchChanged;

  final double minPrice;
  final double maxPrice;
  final RangeValues priceRange;
  final ValueChanged<RangeValues> onPriceChanged;

  final bool hideAllergen;
  final ValueChanged<bool> onHideAllergenChanged;
  final List<String> allergenValues;
  final Set<String> excludedAllergens;
  final ValueChanged<String> onToggleExclude;

  final VoidCallback onClearFilters;

  const _FiltersBar({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.minPrice,
    required this.maxPrice,
    required this.priceRange,
    required this.onPriceChanged,
    required this.hideAllergen,
    required this.onHideAllergenChanged,
    required this.allergenValues,
    required this.excludedAllergens,
    required this.onToggleExclude,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            // Recherche
            TextField(
              controller: searchCtrl,
              onChanged: (_) => onSearchChanged(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher un menu (nom, description)…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            // Price range
            Row(
              children: [
                Text('Prix'),
                Expanded(
                  child: RangeSlider(
                    min: minPrice,
                    max: maxPrice,
                    values: priceRange,
                    divisions: (maxPrice - minPrice).clamp(1, 100).toInt(),
                    labels: RangeLabels(
                      '${priceRange.start.toStringAsFixed(0)}€',
                      '${priceRange.end.toStringAsFixed(0)}€',
                    ),
                    onChanged: (r) => onPriceChanged(r),
                  ),
                ),
                Text('${priceRange.start.toStringAsFixed(0)}–${priceRange.end.toStringAsFixed(0)}€'),
              ],
            ),
            const SizedBox(height: 8),
            // Allergènes
            Row(
              children: [
                Switch(
                  value: hideAllergen,
                  onChanged: onHideAllergenChanged,
                ),
                const Text('Exclure des allergènes'),
                const Spacer(),
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ),
            if (hideAllergen && allergenValues.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: [
                    for (final a in allergenValues)
                      FilterChip(
                        label: Text(a),
                        selected: excludedAllergens.contains(a.toLowerCase()),
                        onSelected: (_) => onToggleExclude(a),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Carte menu + expansion produits + actions panier
class _MenuCard extends StatefulWidget {
  final Menu menu;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _MenuCard({
    required this.menu,
    required this.quantity,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.menu;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // image placeholder
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fastfood),
                ),
                const SizedBox(width: 12),
                // infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.titre, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      if ((m.description ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(m.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: -6,
                        children: [
                          Chip(label: Text('${m.prix.toStringAsFixed(2)} €'), backgroundColor: Colors.green.withOpacity(.1)),
                          if (m.produits.isNotEmpty)
                            Chip(label: Text('${m.produits.length} produit(s)'), backgroundColor: Colors.blueGrey.withOpacity(.08)),
                          if (m.allergenes.isNotEmpty)
                            Chip(label: Text('Allergènes: ${m.allergenes.join(", ")}'), backgroundColor: Colors.orange.withOpacity(.08)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // panier
                widget.quantity <= 0
                    ? ElevatedButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Ajouter'),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: widget.onDec, icon: const Icon(Icons.remove_circle_outline)),
                    Text('${widget.quantity}', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(onPressed: widget.onInc, icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bouton détails produits
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: const Text('Voir les produits'),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: _ProductsList(menu: m),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends StatelessWidget {
  final Menu menu;
  const _ProductsList({required this.menu});

  @override
  Widget build(BuildContext context) {
    if (menu.produits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 12),
        child: Text('Aucun produit pour ce menu.', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    // On suppose que chaque "produit" a au moins un champ nom/libelle ; on gère fallback proprement.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          for (final p in menu.produits)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, size: 20),
              title: Text(_productName(p)),
              subtitle: _productSubtitle(p),
            ),
        ],
      ),
    );
  }

  String _productName(dynamic p) {
    try {
      // tente d'accéder à p.nom ou p.libelle (objets typés)
      // ignore: unnecessary_cast
      final n = (p as dynamic).nom ?? (p as dynamic).libelle ?? (p as dynamic).name;
      if (n != null && n.toString().trim().isNotEmpty) return n.toString();
    } catch (_) {}
    // si c'est une chaîne simple
    if (p is String) return p;
    // fallback générique
    return p.toString();
  }

  Widget? _productSubtitle(dynamic p) {
    try {
      final desc = (p as dynamic).description ?? (p as dynamic).details;
      if (desc != null && desc.toString().trim().isNotEmpty) {
        return Text(desc.toString(), maxLines: 2, overflow: TextOverflow.ellipsis);
      }
    } catch (_) {}
    return null;
  }
}

/// États UI basiques
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Aucun menu ne correspond à vos critères.', style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Erreur: $error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
        ],
      ),
    );
  }
}

extension _CartSelectors on CartState {
  int quantityFor({required int menuId, required int restaurantId}) {
    final match = items.where((it) => it.menu.id == menuId && it.restaurantId == restaurantId);
    if (match.isEmpty) return 0;
    return match.first.quantite ?? 0;
  }
}
