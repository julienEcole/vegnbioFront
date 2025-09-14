import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu.dart';
import '../../providers/panier_provider.dart';
import '../../providers/auth_provider.dart';
import 'menu_image_widget.dart';

/// Widget de carte de menu avec bouton d'ajout au panier
class MenuCardWithCart extends ConsumerWidget {
  final Menu menu;
  final VoidCallback? onTap;

  const MenuCardWithCart({
    super.key,
    required this.menu,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final quantiteDansPanier = ref.watch(quantiteMenuProvider(menu.id));

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du menu
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: MenuImageWidget.createMenuCard(
                imageUrl: menu.imageUrl,
                width: double.infinity,
                height: 200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                fallbackIcon: Icons.restaurant_menu,
                margin: const EdgeInsets.all(0),
              ),
            ),

            // Contenu de la carte
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          menu.titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${menu.prix.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (menu.description != null && menu.description!.isNotEmpty)
                    Text(
                      menu.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Allergènes
                  if (menu.allergenes.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: menu.allergenes.map((allergene) {
                        return Chip(
                          label: Text(
                            allergene,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange[100],
                          labelStyle: TextStyle(color: Colors.orange[800]),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 12),

                  // Boutons d'ajout au panier (seulement pour les utilisateurs connectés)
                  if (authState is AuthenticatedAuthState)
                    _buildCartControls(context, ref, quantiteDansPanier)
                  else
                    _buildLoginPrompt(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartControls(BuildContext context, WidgetRef ref, int quantiteDansPanier) {
    return Row(
      children: [
        // Bouton de diminution
        if (quantiteDansPanier > 0)
          IconButton(
            onPressed: () {
              ref.read(panierProvider.notifier).modifierQuantite(
                menu.id,
                quantiteDansPanier - 1,
              );
            },
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red,
          ),

        // Quantité actuelle
        if (quantiteDansPanier > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$quantiteDansPanier',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),

        const Spacer(),

        // Bouton d'ajout
        ElevatedButton.icon(
          onPressed: () {
            ref.read(panierProvider.notifier).ajouterItem(menu);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${menu.titre} ajouté au panier'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(quantiteDansPanier > 0 ? 'Ajouter' : 'Au panier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            color: Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            'Connectez-vous pour commander',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Navigation vers la page de connexion
              Navigator.of(context).pushNamed('/profil');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
