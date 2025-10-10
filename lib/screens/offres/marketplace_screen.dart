import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/market_browse_provider.dart';

class RestaurateurMarketplaceScreen extends ConsumerWidget {
  const RestaurateurMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketBrowseProvider);
    final filters = ref.watch(marketFiltersProvider);
    final offres = ref.watch(marketFilteredOffresProvider);
    final compareRows = ref.watch(marketCompareRowsProvider);
    final notifier = ref.read(marketBrowseProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place de marché — Restaurateur'),
      ),
      body: _centeredShell(
        child: Column(
          children: [
            // barre de filtres
            _FilterBar(
              query: filters.query,
              onlyAvailable: filters.onlyAvailable,
              currentSort: filters.sort,
              categories: notifier.availableCategories,
              selectedCategoryId: filters.categorieId,
              onQueryChanged: notifier.setQuery,
              onOnlyAvailableChanged: notifier.setOnlyAvailable,
              onSortChanged: notifier.setSort,
              onCategoryChanged: notifier.setCategorieId,
              onRefresh: notifier.load,
            ),

            const SizedBox(height: 10),

            // contenu
            Expanded(
              child: Builder(builder: (_) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return _ErrorBox(
                    message: state.error!,
                    onRetry: notifier.load,
                  );
                }
                if (offres.isEmpty) {
                  return const _EmptyBox();
                }

                return Column(
                  children: [
                    // grille d'offres
                    Expanded(
                      child: _OffresGrid(
                        offres: offres,
                        onToggleCompare: (id) => notifier.toggleCompare(id),
                        selectedIds: state.compareIds.toSet(),
                      ),
                    ),

                    // barre de comparaison si éléments sélectionnés
                    if (state.compareIds.isNotEmpty)
                      _CompareBar(rows: compareRows, onClear: notifier.clearCompare),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centeredShell({required Widget child}) {
    final maxWidth = kIsWeb ? 1200.0 : double.infinity;
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

class _FilterBar extends StatelessWidget {
  final String query;
  final bool onlyAvailable;
  final String currentSort;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onOnlyAvailableChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onRefresh;

  const _FilterBar({
    required this.query,
    required this.onlyAvailable,
    required this.currentSort,
    required this.categories,
    required this.selectedCategoryId,
    required this.onQueryChanged,
    required this.onOnlyAvailableChanged,
    required this.onSortChanged,
    required this.onCategoryChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // recherche
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher un produit…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onQueryChanged,
              ),
            ),

            // catégories
            DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int?>(
                  hint: const Text('Catégorie'),
                  value: selectedCategoryId,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Toutes')),
                    ...categories.map(
                          (c) => DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text((c['nom'] ?? 'Catégorie').toString()),
                      ),
                    ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
            ),

            // dispo
            FilterChip(
              label: const Text('Disponibles'),
              selected: onlyAvailable,
              onSelected: (v) => onOnlyAvailableChanged(v),
              avatar: const Icon(Icons.check_circle_outline, size: 18),
            ),

            // tri
            DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: currentSort,
                  items: const [
                    DropdownMenuItem(value: 'price_asc',  child: Text('Prix croissant')),
                    DropdownMenuItem(value: 'price_desc', child: Text('Prix décroissant')),
                    DropdownMenuItem(value: 'recent',     child: Text('Plus récent')),
                  ],
                  onChanged: (v) => onSortChanged(v ?? 'price_asc'),
                ),
              ),
            ),

            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffresGrid extends StatelessWidget {
  final List<Map<String, dynamic>> offres;
  final void Function(int id) onToggleCompare;
  final Set<int> selectedIds;

  const _OffresGrid({
    required this.offres,
    required this.onToggleCompare,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final crossAxisCount = isWide ? 3 : 1;

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 210,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: offres.length,
      itemBuilder: (_, i) {
        final o = offres[i];
        final id = o['id'] as int;
        final selected = selectedIds.contains(id);

        final titre = (o['titre'] ?? '').toString();
        final desc  = (o['description'] ?? '').toString();
        final prix  = double.tryParse(o['prix']?.toString() ?? '') ?? 0.0;
        final qte   = (o['quantite'] is num) ? (o['quantite'] as num).toDouble() : double.tryParse('${o['quantite']}') ?? 1.0;
        final unite = (o['unite'] ?? '').toString();
        final dispo = (o['disponible'] == true);
        final cat   = (o['categorie']?['nom'] ?? '').toString();
        final fournisseurId = o['userId'];

        final ppu = qte > 0 ? (prix / qte) : prix;

        return Card(
          elevation: selected ? 5 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // header : titre + catégorie
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (cat.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // desc (une ligne)
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                const SizedBox(height: 8),

                // prix + unité + dispo
                Row(
                  children: [
                    Text('${prix.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Text('(${qte == qte.roundToDouble() ? qte.toInt() : qte} $unite)',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    Icon(
                      dispo ? Icons.check_circle : Icons.cancel,
                      color: dispo ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // prix / unité + fournisseur id
                Row(
                  children: [
                    Text('~ ${ppu.toStringAsFixed(2)} €/ $unite',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Fournisseur #$fournisseurId', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),

                const Spacer(),

                // actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onToggleCompare(id),
                      icon: Icon(selected ? Icons.check_box : Icons.check_box_outline_blank),
                      label: const Text('Comparer'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        // Ici tu peux ouvrir une fiche détaillée, ou un modal de contact fournisseur si tu l’as
                        // context.push('/offres/$id');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ouverture de la fiche produit (à implémenter)')),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Détails'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompareBar extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final VoidCallback onClear;
  const _CompareBar({required this.rows, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Comparaison (${rows.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(onPressed: onClear, icon: const Icon(Icons.close), label: const Text('Vider')),
              ],
            ),
            const SizedBox(height: 8),
            // tableau simple
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Produit')),
                  DataColumn(label: Text('Fournisseur')),
                  DataColumn(label: Text('Prix')),
                  DataColumn(label: Text('Qté')),
                  DataColumn(label: Text('Unité')),
                  DataColumn(label: Text('Prix/Unité')),
                  DataColumn(label: Text('Dispo')),
                ],
                rows: rows.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(Text((r['titre'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
                      DataCell(Text('#${r['fournisseurId']}')),
                      DataCell(Text('${double.tryParse(r['prix'].toString())?.toStringAsFixed(2) ?? r['prix']} €')),
                      DataCell(Text('${r['quantite']}')),
                      DataCell(Text('${r['unite']}')),
                      DataCell(Text('${(r['ppu'] as double).toStringAsFixed(2)} €/ ${r['unite']}')),
                      DataCell(Icon((r['disponible'] == true) ? Icons.check_circle : Icons.cancel,
                          color: (r['disponible'] == true) ? Colors.green : Colors.red, size: 18)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aucune offre disponible.'),
    );
  }
}
