import 'package:flutter/material.dart';
import '../../models/panier_item.dart';

class PanierItemCard extends StatelessWidget {
  final PanierItem item;
  final Function(int) onQuantiteChanged;
  final VoidCallback onSupprimer;

  const PanierItemCard({
    super.key,
    required this.item,
    required this.onQuantiteChanged,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du produit
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            
            const SizedBox(width: 16),
            
            // Informations du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.prixText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Contrôles de quantité et suppression
            Column(
              children: [
                // Bouton supprimer
                IconButton(
                  onPressed: onSupprimer,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  tooltip: 'Supprimer',
                ),
                
                // Contrôles de quantité
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton moins
                      IconButton(
                        onPressed: item.quantite > 1
                            ? () => onQuantiteChanged(item.quantite - 1)
                            : null,
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
                          item.quantite.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      // Bouton plus
                      IconButton(
                        onPressed: () => onQuantiteChanged(item.quantite + 1),
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
                ),
                
                const SizedBox(height: 8),
                
                // Total de la ligne
                Text(
                  item.totalLigneText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}
