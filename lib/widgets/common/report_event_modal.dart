import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/models/report_request.dart';
import 'package:vegnbio_front/providers/report_provider.dart';
import 'package:vegnbio_front/providers/auth_provider.dart';
import 'package:vegnbio_front/models/report.dart';

class ReportEventModal extends ConsumerStatefulWidget {
  final int eventId;
  final int? restaurantId;

  const ReportEventModal({super.key, required this.eventId, this.restaurantId});

  @override
  ConsumerState<ReportEventModal> createState() => _ReportEventModalState();
}

class _ReportEventModalState extends ConsumerState<ReportEventModal> {
  final _formKey = GlobalKey<FormState>();
  ReportCategory _category = ReportCategory.securite;
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flag, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Signaler cet événement'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReportCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: ReportCategory.securite, child: Text('Sécurité / allergènes')),
                  DropdownMenuItem(value: ReportCategory.inapproprie, child: Text('Contenu inapproprié')),
                  DropdownMenuItem(value: ReportCategory.mensonger, child: Text('Information mensongère')),
                  DropdownMenuItem(value: ReportCategory.fraude, child: Text('Fraude / arnaque')),
                  DropdownMenuItem(value: ReportCategory.autre, child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _category = v ?? ReportCategory.autre),
                validator: (v) => v == null ? 'Choisissez une catégorie' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expliquez votre signalement *',
                  hintText: 'Décrivez précisément le problème…',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
                validator: (v) =>
                (v == null || v.trim().length < 10) ? 'Min. 10 caractères' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send),
          label: const Text('Envoyer'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final req = ReportRequest(
      targetType: ReportTarget.evenement,
      targetId: widget.eventId,
      restaurantId: widget.restaurantId,
      category: _category,
      message: _messageCtrl.text.trim(),
    );

    try {
      // 🔐 Récupérer le JWT depuis authProvider
      final auth = ref.read(authProvider);
      final token = auth.token; // adapte si autre propriété

      if (token == null || token.isEmpty) {
        throw Exception('Vous devez être connecté pour signaler.');
      }

      await ref.read(reportingServiceProvider).createReport(req, token: token);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signalement envoyé, merci !'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

}
