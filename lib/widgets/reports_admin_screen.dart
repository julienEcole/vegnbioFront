// lib/widgets/reports_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/providers/reports_admin_provider.dart';

class ReportsAdminScreen extends ConsumerWidget {
  const ReportsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // print('🧭 ReportsAdminScreen BUILD');
    final asyncList = ref.watch(reportsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modération — Signalements')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FiltersBar(),
            const SizedBox(height: 12),
            Expanded(
              child: asyncList.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => SingleChildScrollView(
                  child: SelectableText('Erreur: $e\n\n$st'),
                ),
                data: (resp) {
                  if (resp.data.isEmpty) {
                    return const Center(child: Text('Aucun signalement.'));
                  }
                  return _ReportsTable();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(reportsFilterProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Statut
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            value: f.status,
            items: const [
              DropdownMenuItem(value: null, child: Text('Statut — Tous')),
              DropdownMenuItem(value: 'open', child: Text('Ouvert')),
              DropdownMenuItem(value: 'in_review', child: Text('En cours')),
              DropdownMenuItem(value: 'resolved', child: Text('Résolu')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
            ],
            onChanged: (v) => ref.read(reportsFilterProvider.notifier).state = f.copyWith(status: v, page: 1),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        // Catégorie
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            value: f.category,
            items: const [
              DropdownMenuItem(value: null, child: Text('Catégorie — Toutes')),
              DropdownMenuItem(value: 'securite', child: Text('Sécurité')),
              DropdownMenuItem(value: 'inapproprie', child: Text('Inapproprié')),
              DropdownMenuItem(value: 'mensonger', child: Text('Mensongère')),
              DropdownMenuItem(value: 'fraude', child: Text('Fraude')),
            ],
            onChanged: (v) => ref.read(reportsFilterProvider.notifier).state = f.copyWith(category: v, page: 1),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        // Type de cible
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            value: f.targetType,
            items: const [
              DropdownMenuItem(value: null, child: Text('Cible — Toutes')),
              DropdownMenuItem(value: 'evenement', child: Text('Événement')),
              DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
              DropdownMenuItem(value: 'utilisateur', child: Text('Utilisateur')),
              DropdownMenuItem(value: 'menu', child: Text('Menu')),
              DropdownMenuItem(value: 'offre', child: Text('Offre')),
            ],
            onChanged: (v) => ref.read(reportsFilterProvider.notifier).state = f.copyWith(targetType: v, page: 1),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        // Recherche
        SizedBox(
          width: 260,
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher...', border: OutlineInputBorder()),
            onSubmitted: (v) => ref.read(reportsFilterProvider.notifier).state = f.copyWith(q: v, page: 1),
          ),
        ),
        // Refresh
        IconButton(
          tooltip: 'Actualiser',
          onPressed: () => ref.invalidate(reportsListProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _ReportsTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resp = ref.watch(reportsListProvider).value!;
    final items = resp.data;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              return ListTile(
                leading: CircleAvatar(child: Text(r.id.toString())),
                title: Text('${r.targetType.name} #${r.targetId} — ${r.category.name} — ${r.status.name}'),
                subtitle: Text(r.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusBtn(id: r.id, newStatus: 'in_review', label: 'Prendre'),
                    _StatusBtn(id: r.id, newStatus: 'resolved', label: 'Résoudre'),
                    _StatusBtn(id: r.id, newStatus: 'rejeter', label: 'Rejeter'), // if back expects 'rejected', change here
                  ],
                ),
              );
            },
          ),
        ),
        _PaginationFooter(),
      ],
    );
  }
}

class _StatusBtn extends ConsumerWidget {
  final int id;
  final String newStatus;
  final String label;
  const _StatusBtn({required this.id, required this.newStatus, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () async {
          try {
            await ref.read(updateReportStatusProvider((id: id, status: newStatus, note: null)).future);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Statut mis à jour → $newStatus')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        },
        child: Text(label),
      ),
    );
  }
}

class _PaginationFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(reportsFilterProvider);
    final resp = ref.watch(reportsListProvider).value;
    final total = resp?.total ?? 0;
    final pageCount = (total / f.pageSize).ceil().clamp(1, 999999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Total: $total  |  Page ${f.page} / $pageCount'),
        IconButton(
          onPressed: f.page > 1 ? () {
            ref.read(reportsFilterProvider.notifier).state = f.copyWith(page: f.page - 1);
          } : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: f.page < pageCount ? () {
            ref.read(reportsFilterProvider.notifier).state = f.copyWith(page: f.page + 1);
          } : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
