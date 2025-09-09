import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/commande_provider.dart';
import '../models/commande.dart';
import '../widgets/commande/commande_card.dart';
import '../widgets/commande/commande_stats_widget.dart';

class CommandesScreen extends ConsumerWidget {
  const CommandesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(commandesProvider);
    final statsAsync = ref.watch(commandesStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(commandesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques
          statsAsync.when(
            data: (stats) => CommandeStatsWidget(stats: stats),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erreur: $error'),
              ),
            ),
          ),
          
          // Liste des commandes
          Expanded(
            child: commandesAsync.when(
              data: (commandes) {
                if (commandes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune commande trouvée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: commandes.length,
                  itemBuilder: (context, index) {
                    final commande = commandes[index];
                    return CommandeCard(
                      commande: commande,
                      onTap: () => _showCommandeDetails(context, ref, commande),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement des commandes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(commandesProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCommandeDialog(context, ref),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCommandeDetails(BuildContext context, WidgetRef ref, Commande commande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeDetailScreen(commande: commande),
      ),
    );
  }

  void _showCreateCommandeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateCommandeDialog(),
    );
  }
}

class CommandeDetailScreen extends ConsumerWidget {
  final Commande commande;

  const CommandeDetailScreen({super.key, required this.commande});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${commande.id}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleStatusChange(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pending',
                child: Text('Marquer en attente'),
              ),
              const PopupMenuItem(
                value: 'paid',
                child: Text('Marquer comme payée'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Annuler'),
              ),
              const PopupMenuItem(
                value: 'refunded',
                child: Text('Rembourser'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${commande.id}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(commande.statut),
                          color: _getStatusColor(commande.statut),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          commande.statut.displayName,
                          style: TextStyle(
                            color: _getStatusColor(commande.statut),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Restaurant ID: ${commande.restaurantId}'),
                    Text('Créée le: ${_formatDate(commande.createdAt)}'),
                    Text('Modifiée le: ${_formatDate(commande.updatedAt)}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Items de la commande
            Text(
              'Articles (${commande.nombreItems})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            ...commande.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.nom),
                subtitle: Text('Quantité: ${item.quantite}'),
                trailing: Text(
                  item.totalLigneText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )),
            
            const SizedBox(height: 16),
            
            // Totaux
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total HT:'),
                        Text(commande.prixHTText),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TVA (${commande.tvaRate}%):'),
                        Text(commande.tvaText),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total TTC:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          commande.prixText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.draft:
        return Icons.edit;
      case CommandeStatut.pending:
        return Icons.schedule;
      case CommandeStatut.paid:
        return Icons.check_circle;
      case CommandeStatut.cancelled:
        return Icons.cancel;
      case CommandeStatut.refunded:
        return Icons.refresh;
    }
  }

  Color _getStatusColor(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.draft:
        return Colors.grey;
      case CommandeStatut.pending:
        return Colors.orange;
      case CommandeStatut.paid:
        return Colors.green;
      case CommandeStatut.cancelled:
        return Colors.red;
      case CommandeStatut.refunded:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleStatusChange(BuildContext context, WidgetRef ref, String newStatus) {
    ref.read(commandeNotifierProvider.notifier).updateStatut(commande.id, newStatus);
    Navigator.pop(context);
  }
}

class CreateCommandeDialog extends ConsumerWidget {
  const CreateCommandeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Nouvelle Commande'),
      content: const Text('Fonctionnalité de création de commande à implémenter'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implémenter la création de commande
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
