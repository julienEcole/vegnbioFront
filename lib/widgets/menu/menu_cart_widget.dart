import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/panier_provider.dart';
import '../../models/menu.dart';
import '../../widgets/panier/panier_badge.dart';

class MenuAddToCartButton extends ConsumerWidget {
  final Menu menu;
  final VoidCallback? onAdded;

  const MenuAddToCartButton({
    super.key,
    required this.menu,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantiteDansPanier = ref.watch(quantiteMenuProvider(menu.id));

    if (quantiteDansPanier > 0) {
      // Afficher les contrôles de quantité
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton moins
            IconButton(
              onPressed: () {
                ref.read(panierProvider.notifier).modifierQuantite(
                  menu.id,
                  quantiteDansPanier - 1,
                );
              },
              icon: const Icon(Icons.remove),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            
            // Quantité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                quantiteDansPanier.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            // Bouton plus
            IconButton(
              onPressed: () {
                ref.read(panierProvider.notifier).ajouterItem(menu);
              },
              icon: const Icon(Icons.add),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      );
    } else {
      // Afficher le bouton "Ajouter au panier"
      return ElevatedButton.icon(
        onPressed: () {
          ref.read(panierProvider.notifier).ajouterItem(menu);
          onAdded?.call();
          
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${menu.titre} ajouté au panier'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Voir le panier',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Naviguer vers le panier
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Ajouter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      );
    }
  }
}

class MenuCardWithCart extends ConsumerWidget {
  final Menu menu;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showAdminActions;

  const MenuCardWithCart({
    super.key,
    required this.menu,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showAdminActions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantiteDansPanier = ref.watch(quantiteMenuProvider(menu.id));

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du menu
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: menu.imageUrl != null
                  ? Image.network(
                      menu.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            
            // Contenu de la carte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:                         Text(
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (menu.description != null) ...[
                    Text(
                      menu.description!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Allergènes
                  if (menu.allergenes.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: menu.allergenes.map((allergene) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            allergene,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton d'ajout au panier
                      Expanded(
                        child: MenuAddToCartButton(
                          menu: menu,
                          onAdded: () {
                            // Optionnel: action après ajout
                          },
                        ),
                      ),
                      
                      // Actions admin (si activées)
                      if (showAdminActions) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                  
                  // Indicateur de quantité dans le panier
                  if (quantiteDansPanier > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$quantiteDansPanier dans le panier',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Icon(
        Icons.restaurant,
        size: 80,
        color: Colors.grey,
      ),
    );
  }
}
