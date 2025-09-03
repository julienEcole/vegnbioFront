import 'package:flutter/material.dart';
import '../models/menu.dart';

class MenuDetailCard extends StatelessWidget {
  final Menu menu;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MenuDetailCard({
    super.key,
    required this.menu,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    menu.titre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Modifier',
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Text('🗑️', style: TextStyle(fontSize: 20)),
                    tooltip: 'Supprimer',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Prix et disponibilité
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    menu.prixText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: menu.disponible ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    menu.disponible ? '✅ Disponible' : '❌ Indisponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: menu.disponible ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (menu.description != null && menu.description!.isNotEmpty) ...[
              Text(
                '📝 Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                menu.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '📅 ${menu.formattedDate}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Produits
            Text(
              '🍽️ Produits du menu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (menu.produits.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menu.produits.map((produit) {
                  return Chip(
                    label: Text(produit),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade200),
                  );
                }).toList(),
              )
            else
              Text(
                'Aucun produit détaillé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),

            // Allergènes
            Text(
              '⚠️ Allergènes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (menu.allergenes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menu.allergenes.map((allergene) {
                  return Chip(
                    label: Text(allergene),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade200),
                  );
                }).toList(),
              )
            else
              Text(
                'Aucun allergène signalé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
