import 'package:flutter/material.dart';
import '../models/commande.model.dart';
import '../screens/commandes/client_orders_screen.dart';
import '../screens/commandes/restaurateur_orders_screen.dart';
import '../screens/commandes/admin_orders_screen.dart';

class CommandeViewFactory {
  /// Créer la vue appropriée selon le rôle de l'utilisateur
  static Widget createCommandeView({
    required String userRole,
    required int userId,
    int? restaurantId,
    String? token,
  }) {
    switch (userRole.toLowerCase()) {
      case 'client':
        return ClientOrdersScreen(
          userId: userId,
          token: token,
        );
      
      case 'restaurateur':
      case 'fournisseur':
        return RestaurateurOrdersScreen(
          userId: userId,
          restaurantId: restaurantId,
          token: token,
        );
      
      case 'admin':
        return AdminOrdersScreen(
          userId: userId,
          token: token,
        );
      
      default:
        return _buildErrorView('Rôle non reconnu: $userRole');
    }
  }

  /// Créer une vue d'erreur
  static Widget _buildErrorView(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: Colors.red,
      ),
      body: Center(
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
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Retourner à l'écran précédent
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  /// Créer un widget de statut de commande
  static Widget buildStatusChip(String statut) {
    final commande = Commande(
      id: 0,
      restaurantId: 0,
      statut: statut,
      currency: 'EUR',
      totalHT: 0,
      totalTVA: 0,
      totalTTC: 0,
      tvaRate: 10,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Chip(
      label: Text(
        commande.statusDisplayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(int.parse(commande.statusColor.replaceFirst('#', '0xFF'))),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  /// Créer un widget d'informations de paiement
  static Widget buildPaymentInfo(PaymentInfo? paymentInfo) {
    if (paymentInfo == null) {
      return const ListTile(
        leading: Icon(Icons.payment, color: Colors.grey),
        title: Text('Aucune information de paiement'),
        subtitle: Text('Commande non payée'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.credit_card, size: 20),
                const SizedBox(width: 8),
                Text(paymentInfo.cardDisplay),
              ],
            ),
            if (paymentInfo.paidAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text('Payé le ${_formatDate(paymentInfo.paidAt!)}'),
                ],
              ),
            ],
            if (paymentInfo.amount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.euro, size: 20),
                  const SizedBox(width: 8),
                  Text('${(paymentInfo.amount! / 100).toStringAsFixed(2)} €'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Créer un widget d'informations de livraison
  static Widget buildDeliveryInfo(DeliveryInfo? deliveryInfo) {
    if (deliveryInfo == null) {
      return const ListTile(
        leading: Icon(Icons.local_shipping, color: Colors.grey),
        title: Text('Aucune information de livraison'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  deliveryInfo.type == 'pickup' 
                      ? Icons.store 
                      : Icons.local_shipping,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(deliveryInfo.typeDisplay),
              ],
            ),
            if (deliveryInfo.address != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(deliveryInfo.address!)),
                ],
              ),
            ],
            if (deliveryInfo.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Text(deliveryInfo.phone!),
                ],
              ),
            ],
            if (deliveryInfo.estimatedTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text('Estimation: ${_formatDateTime(deliveryInfo.estimatedTime!)}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Créer un widget de liste d'articles
  static Widget buildItemsList(List<CommandeItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Articles commandés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.nom} x${item.quantite}'),
                  ),
                  Text('${item.totalLigne.toStringAsFixed(2)} €'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Créer un widget d'actions pour les restaurateurs
  static Widget buildRestaurateurActions({
    required Commande commande,
    required Function(String) onStatusUpdate,
    required Function() onVerifyPayment,
    required Function(String) onMarkSuspicious,
    required Function(String) onCancel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Vérifier le paiement
                ElevatedButton.icon(
                  onPressed: onVerifyPayment,
                  icon: const Icon(Icons.verified_user, size: 16),
                  label: const Text('Vérifier paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Actions selon le statut
                if (commande.statut == 'paid')
                  ElevatedButton.icon(
                    onPressed: () => onStatusUpdate('confirmed'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (commande.statut == 'confirmed')
                  ElevatedButton.icon(
                    onPressed: () => onStatusUpdate('preparing'),
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('En préparation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (commande.statut == 'preparing')
                  ElevatedButton.icon(
                    onPressed: () => onStatusUpdate('ready'),
                    icon: const Icon(Icons.done, size: 16),
                    label: const Text('Prête'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (commande.statut == 'ready')
                  ElevatedButton.icon(
                    onPressed: () => onStatusUpdate('delivered'),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Livrée'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                // Marquer comme suspecte
                ElevatedButton.icon(
                  onPressed: () => onMarkSuspicious('Commande suspecte'),
                  icon: const Icon(Icons.warning, size: 16),
                  label: const Text('Suspecte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Annuler
                if (commande.canBeCancelled)
                  ElevatedButton.icon(
                    onPressed: () => onCancel('Annulée par le restaurateur'),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Annuler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Créer un widget d'actions pour les admins
  static Widget buildAdminActions({
    required Commande commande,
    required Function(String) onRefund,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Remboursement
                if (commande.canBeRefunded)
                  ElevatedButton.icon(
                    onPressed: () => onRefund('Remboursement demandé par l\'admin'),
                    icon: const Icon(Icons.money_off, size: 16),
                    label: const Text('Rembourser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formater une date et heure
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
