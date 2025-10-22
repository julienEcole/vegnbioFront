import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/offres_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';

class MesOffresScreen extends ConsumerStatefulWidget {
  const MesOffresScreen({super.key});
  @override
  ConsumerState<MesOffresScreen> createState() => _MesOffresScreenState();
}

class _MesOffresScreenState extends ConsumerState<MesOffresScreen> {
  String _search = '';
  String _filtreDispo = 'Tous'; // Tous | Disponibles | Suspendues

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mesOffresProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider);
    final role = (me.userRole ?? me.role ?? me.effectiveRole)?.toLowerCase();
    final isAllowed =
        me.isAuthenticated && (role == 'fournisseur' || role == 'admin');

    if (!isAllowed) {
      return const Center(
        child: Text('Accès réservé aux fournisseurs / admins'),
      );
    }

    final state = ref.watch(mesOffresProvider);

    // ✅ wrapper Material pour corriger "No Material widget found"
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- Header (titre + bouton Créer) ----------
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mes offres',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openCreateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer une offre'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---------- Barre recherche + filtre ----------
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher par titre, description…',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        isDense: true,
                        value: _filtreDispo,
                        decoration: const InputDecoration(
                          labelText: 'Disponibilité',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(
                              value: 'Disponibles',
                              child: Text('Disponibles')),
                          DropdownMenuItem(
                              value: 'Suspendues', child: Text('Suspendues')),
                        ],
                        onChanged: (v) =>
                            setState(() => _filtreDispo = v ?? 'Tous'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (state.loading) const LinearProgressIndicator(),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),

                const SizedBox(height: 8),
                // ✅ Flexible au lieu de Expanded pour éviter overflow
                Flexible(child: _buildList(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final state = ref.watch(mesOffresProvider);

    // filtres client: search + disponibilité
    final items = state.items.where((o) {
      final titre = (o['titre'] ?? '').toString().toLowerCase();
      final desc = (o['description'] ?? '').toString().toLowerCase();
      final q = _search.toLowerCase();
      final matchSearch =
          _search.isEmpty || titre.contains(q) || desc.contains(q);

      final dispo = (o['disponible'] == true);
      final matchDispo = switch (_filtreDispo) {
        'Disponibles' => dispo,
        'Suspendues' => !dispo,
        _ => true,
      };

      return matchSearch && matchDispo;
    }).toList();

    if (items.isEmpty) {
      return const Center(child: Text('Aucune offre'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final o = items[i];
        final id = o['id'] as int;
        final dispo = (o['disponible'] == true);

        return Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o['titre']?.toString() ?? '—',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o['description']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _ChipInfo(
                              icon: Icons.attach_money,
                              label: o['prix']?.toString() ?? '—'),
                          _ChipInfo(
                              icon: Icons.inventory_2,
                              label:
                              '${o['quantite'] ?? '—'} ${o['unite'] ?? ''}'),
                          _ChipInfo(
                            icon: dispo
                                ? Icons.check_circle
                                : Icons.pause_circle_filled,
                            label:
                            dispo ? 'Disponible' : 'Suspendue',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Actions
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openEditDialog(context, o),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _toggle(id),
                      icon:
                      Icon(dispo ? Icons.pause : Icons.play_arrow),
                      label:
                      Text(dispo ? 'Suspendre' : 'Activer'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(context, id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
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

  Future<void> _toggle(int id) async {
    await ref.read(mesOffresProvider.notifier).toggle(id);
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’offre ?'),
        content: const Text(
            'Cette action est définitive. Confirmer la suppression ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(mesOffresProvider.notifier).remove(id);
    }
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _OffreDialog(),
    );
    if (payload != null) {
      await ref.read(mesOffresProvider.notifier).create(payload);
    }
  }

  Future<void> _openEditDialog(
      BuildContext context, Map<String, dynamic> offre) async {
    final patch = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _OffreDialog(initial: offre),
    );
    if (patch != null) {
      await ref
          .read(mesOffresProvider.notifier)
          .update(offre['id'] as int, patch);
    }
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _OffreDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _OffreDialog({this.initial});

  @override
  State<_OffreDialog> createState() => _OffreDialogState();
}

class _OffreDialogState extends State<_OffreDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titre;
  late TextEditingController _description;
  late TextEditingController _prix;
  late TextEditingController _quantite;
  late TextEditingController _unite;

  static const allowedUnits = ['kg', 'gr', 'piece'];
  String? _uniteValue;

  @override
  void initState() {
    super.initState();
    _titre =
        TextEditingController(text: widget.initial?['titre']?.toString() ?? '');
    _description = TextEditingController(
        text: widget.initial?['description']?.toString() ?? '');
    _prix =
        TextEditingController(text: widget.initial?['prix']?.toString() ?? '');
    _quantite = TextEditingController(
        text: widget.initial?['quantite']?.toString() ?? '');
    _unite =
        TextEditingController(text: widget.initial?['unite']?.toString() ?? '');
    //_uniteValue = widget.initial?.unite ?? 'kg';
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _prix.dispose();
    _quantite.dispose();
    _unite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    const allowedUnits = ['kg', 'gr', 'piece'];

    return AlertDialog(
      title: Text(isEdit ? 'Modifier l’offre' : 'Créer une offre'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titre,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),

              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prix,
                      decoration: const InputDecoration(
                        labelText: 'Prix (entier, ex: 990 pour 9,90€)',
                        hintText: 'en centimes',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <-- nécessite l’import services.dart
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatoire';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Nombre entier positif requis';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantite,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatoire';
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Entier > 0 requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _uniteValue, // <-- utilise la variable d’état
                items: allowedUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _uniteValue = v),
                decoration: const InputDecoration(labelText: 'Unité'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;

            // Parsing fiable
            final prixCents = int.parse(_prix.text.trim());       // ex: 990 pour 9,90€
            final quantite = int.parse(_quantite.text.trim());
            final unite = _uniteValue!;

            final payload = {
              'titre': _titre.text.trim(),
              'description': _description.text.trim().isEmpty ? null : _description.text.trim(),

              // ✅ Prix entier (long) + quantité int + unité depuis la liste
              'prix': prixCents,
              'quantite': quantite,
              'unite': unite,
            };

            Navigator.pop(context, payload);
          },
          child: Text(isEdit ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }

}
