import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/panier_provider.dart';
import '../models/panier_item.dart';
import '../widgets/panier/panier_item_card.dart';
import '../widgets/panier/panier_summary_widget.dart';
import '../login_screen.dart';

class PanierScreen extends ConsumerWidget {
  const PanierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panier = ref.watch(panierProvider);
    final stats = ref.watch(panierStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!stats['estVide'])
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showViderPanierDialog(context, ref),
            ),
        ],
      ),
      body: stats['estVide'] ? _buildEmptyPanier(context) : _buildPanierContent(context, ref, panier, stats),
      bottomNavigationBar: stats['estVide'] ? null : _buildCheckoutButton(context, ref),
    );
  }

  Widget _buildEmptyPanier(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 24),
          Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Ajoutez des plats délicieux à votre panier\npour commencer votre commande',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanierContent(BuildContext context, WidgetRef ref, List<PanierItem> panier, Map<String, dynamic> stats) {
    return Column(
      children: [
        // Résumé du panier
        PanierSummaryWidget(stats: stats),
        
        // Liste des articles
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: panier.length,
            itemBuilder: (context, index) {
              final item = panier[index];
              return PanierItemCard(
                item: item,
                onQuantiteChanged: (nouvelleQuantite) {
                  ref.read(panierProvider.notifier).modifierQuantite(
                    item.menuId,
                    nouvelleQuantite,
                  );
                },
                onSupprimer: () {
                  ref.read(panierProvider.notifier).supprimerItem(item.menuId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${ref.watch(panierStatsProvider)['totalTTC'].toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Bouton de commande
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _navigateToCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Passer la commande',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }

  void _showViderPanierDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir supprimer tous les articles de votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(panierProvider.notifier).viderPanier();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panier = ref.watch(panierProvider);
    final stats = ref.watch(panierStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message d'authentification
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Authentification requise',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vous devez être connecté pour finaliser votre commande.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Résumé de la commande
            Text(
              'Résumé de votre commande',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            PanierSummaryWidget(stats: stats),
            
            const SizedBox(height: 24),
            
            // Liste des articles
            Text(
              'Articles (${stats['nombreArticles']})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            ...panier.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.restaurant),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restaurant),
                      ),
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
            
            const SizedBox(height: 32),
            
            // Bouton de connexion
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Se connecter pour commander',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton retour
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Retour au panier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
