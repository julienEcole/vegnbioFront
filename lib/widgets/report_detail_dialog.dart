import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/providers/reports_admin_provider.dart';
import 'package:vegnbio_front/widgets/reports_admin_screen.dart';

class ReportDetailDialog extends ConsumerWidget {
  final int reportId;
  const ReportDetailDialog({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reportDetailProvider(reportId));
    final noteCtrl = TextEditingController();

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 760,
        child: detail.when(
          data: (r) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signalement #${r.id}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _chip('Statut', r.status.name, _statusColor(r.status)),
                        _chip('Cible', r.targetType.name, Colors.blue),
                        _chip('Catégorie', r.category.name, Colors.deepPurple),
                      ]),
                      const SizedBox(height: 12),
                      Text('Message', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: _box(),
                        child: Text(r.message),
                      ),
                      const SizedBox(height: 12),
                      Text('Informations', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: _box(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Créé le : ${r.createdAt}'),
                            if (r.resolvedAt != null) Text('Résolu le : ${r.resolvedAt}'),
                            if (r.reporterEmail != null) Text('Auteur : ${r.reporterEmail}'),
                            if (r.moderatorEmail != null) Text('Modéré par : ${r.moderatorEmail}'),
                            if (r.restaurantId != null) Text('Restaurant ID : ${r.restaurantId}'),
                            Text('Target ID : ${r.targetId}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Panneau d’actions à droite
              Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
                ),
                child: _ActionsPanel(reportId: r.id, current: r.status, noteCtrl: noteCtrl),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(height: 240, child: Center(child: Text('Erreur: $e'))),
        ),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.of(context).pop(), child: const Text('Fermer')),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.withOpacity(0.25)),
  );

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.open: return Colors.red;
      case ReportStatus.in_review: return Colors.orange;
      case ReportStatus.resolved: return Colors.green;
      case ReportStatus.rejected: return Colors.grey;
    }
  }
}

class _ActionsPanel extends ConsumerStatefulWidget {
  final int reportId;
  final ReportStatus current;
  final TextEditingController noteCtrl;
  const _ActionsPanel({required this.reportId, required this.current, required this.noteCtrl});

  @override
  ConsumerState<_ActionsPanel> createState() => _ActionsPanelState();
}

class _ActionsPanelState extends ConsumerState<_ActionsPanel> {
  bool _loading = false;

  Future<void> _update(String status) async {
    setState(()=>_loading=true);
    try {
      await ref.read(updateReportStatusProvider((id: widget.reportId, status: status, note: widget.noteCtrl.text)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mis à jour'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(()=>_loading=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: widget.noteCtrl,
          minLines: 2, maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _loading ? null : ()=>_update('in_review'),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Prendre'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : ()=>_update('resolved'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Résoudre'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : ()=>_update('rejected'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Rejeter'),
              ),
            ],
          ),
        ),
        if (_loading) const Padding(
          padding: EdgeInsets.only(top: 12),
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}
