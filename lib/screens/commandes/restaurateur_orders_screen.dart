import 'package:flutter/material.dart';
import '../../models/commande.model.dart';
import '../../models/restaurant.dart';
import '../../services/commande.service.dart';
import '../../services/restaurant_service.dart';
import '../../factories/commande_view_factory.dart';

class RestaurateurOrdersScreen extends StatefulWidget {
  final int userId;
  final int? restaurantId;
  final String? token;

  const RestaurateurOrdersScreen({
    Key? key,
    required this.userId,
    this.restaurantId,
    this.token,
  }) : super(key: key);

  @override
  State<RestaurateurOrdersScreen> createState() => _RestaurateurOrdersScreenState();
}

class _RestaurateurOrdersScreenState extends State<RestaurateurOrdersScreen> {
  List<Commande> _allCommandes = []; // Toutes les commandes
  List<Commande> _filteredCommandes = []; // Commandes après filtrage local
  List<Restaurant> _restaurants = [];
  List<int> _availableMenuIds = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  int? _selectedRestaurantId;
  int? _selectedMenuId;

  final List<String> _statusOptions = [
    'Tous',
    'pending',
    'paid',
    'confirmed',
    'preparing',
    'ready',
    'delivered',
    'cancelled',
    'refunded',
    'suspicious',
    'to_pay_restaurant',  
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _loadCommandes();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await RestaurantService.getAllRestaurants();
      setState(() {
        _restaurants = restaurants;
      });
    } catch (e) {
      // print('❌ [RestaurateurOrdersScreen] Erreur lors du chargement des restaurants: $e');
    }
  }

  Future<void> _loadCommandes({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Restaurateur: récupérer TOUTES les commandes d'un coup (pas de pagination)
      final result = await CommandeService.getAllRestaurantsCommandes(
        status: null, // Pas de filtre serveur, on filtre localement
        menuId: null, // Pas de filtre serveur, on filtre localement
        limit: 10000, // Grande limite pour tout récupérer
        offset: 0,
        token: widget.token,
      );

      if (result['success']) {
        setState(() {
          _allCommandes = result['commandes'];
          _extractAvailableMenuIds();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _extractAvailableMenuIds() {
    final Set<int> menuIds = {};
    for (final commande in _allCommandes) {
      for (final item in commande.items) {
        if (item.menuId != null) {
          menuIds.add(item.menuId!);
        }
      }
    }
    _availableMenuIds = menuIds.toList()..sort();
  }

  void _applyFilters() {
    List<Commande> filtered = List.from(_allCommandes);

    // Filtre local par statut
    if (_selectedStatus != null && _selectedStatus != 'Tous') {
      filtered = filtered.where((c) => c.statut == _selectedStatus).toList();
    }

    // Filtre local par restaurant
    if (_selectedRestaurantId != null) {
      filtered = filtered.where((c) => c.restaurantId == _selectedRestaurantId).toList();
    }

    // Filtre local par menu
    if (_selectedMenuId != null) {
      filtered = filtered.where((c) => 
        c.items.any((item) => item.menuId == _selectedMenuId)
      ).toList();
    }

    // Tri par date desc
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredCommandes = filtered;
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _onRestaurantFilterChanged(int? restaurantId) {
    setState(() {
      _selectedRestaurantId = restaurantId;
      _selectedMenuId = null; // Réinitialiser le filtre menu
      _applyFilters();
    });
  }

  void _onMenuFilterChanged(int? menuId) {
    setState(() {
      _selectedMenuId = menuId;
      _applyFilters();
    });
  }

  Future<void> _updateStatus(Commande commande, String newStatus) async {
    try {
      final result = await CommandeService.updateStatut(
        commandeId: commande.id,
        statut: newStatus,
        token: widget.token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusDisplayName(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCommandes(refresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyPayment(Commande commande) async {
    try {
      final result = await CommandeService.verifyPayment(
        commandeId: commande.id,
        token: widget.token,
      );

      if (result['success']) {
        final isValid = result['isValid'] as bool;
        final details = result['details'] as Map<String, dynamic>;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isValid ? 'Paiement Valide' : 'Paiement Invalide'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVerificationSection(
                    'Statut Stripe',
                    details['stripeStatus']?.toString().toUpperCase() ?? '',
                    details['statusMatch'] == true,
                  ),
                  const Divider(height: 24),
                  _buildVerificationSection(
                    'Montant',
                    '${details['stripeAmount']} ${details['stripeCurrency']} (Stripe)\n${details['orderAmount']} ${details['orderCurrency']} (Commande)',
                    details['amountMatch'] == true,
                  ),
                  const Divider(height: 24),
                  _buildVerificationSection(
                    'Devise',
                    '${details['stripeCurrency']} = ${details['orderCurrency']}',
                    details['currencyMatch'] == true,
                  ),
                  const Divider(height: 24),
                  _buildVerificationInfoRow('ID Transaction', details['paymentIntentId']),
                  const SizedBox(height: 8),
                  _buildVerificationInfoRow('Date', _formatVerificationDate(details['created'])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildVerificationSection(String title, String value, bool isValid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isValid ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationInfoRow(String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _formatVerificationDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Future<void> _markAsSuspicious(Commande commande, String reason) async {
    try {
      final result = await CommandeService.markAsSuspicious(
        commandeId: commande.id,
        reason: reason,
        token: widget.token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquée comme suspecte'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadCommandes(refresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelCommande(Commande commande, String reason) async {
    try {
      final result = await CommandeService.cancelCommande(
        commandeId: commande.id,
        reason: reason,
        token: widget.token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande annulée'),
            backgroundColor: Colors.red,
          ),
        );
        _loadCommandes(refresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes Restaurant'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCommandes(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtre par restaurant
                DropdownButtonFormField<int>(
                  value: _selectedRestaurantId,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tous les restaurants'),
                    ),
                    ..._restaurants.map((restaurant) {
                      return DropdownMenuItem<int>(
                        value: restaurant.id,
                        child: Text(restaurant.nom),
                      );
                    }).toList(),
                  ],
                  onChanged: _onRestaurantFilterChanged,
                ),
                const SizedBox(height: 12),
                
                // Filtre par statut
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par statut',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status == 'Tous' ? 'Tous les statuts' : _getStatusDisplayName(status)),
                    );
                  }).toList(),
                  onChanged: _onStatusFilterChanged,
                ),
                const SizedBox(height: 12),
                
                // Filtre par menu
                DropdownButtonFormField<int>(
                  value: _selectedMenuId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par menu (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tous les menus'),
                    ),
                    ..._availableMenuIds.map((menuId) {
                      return DropdownMenuItem<int>(
                        value: menuId,
                        child: Text('Menu #$menuId'),
                      );
                    }),
                  ],
                  onChanged: _onMenuFilterChanged,
                ),
              ],
            ),
          ),
          
          // Liste des commandes
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _filteredCommandes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCommandes(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredCommandes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune commande trouvée',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCommandes(refresh: true),
      child: ListView.builder(
        itemCount: _filteredCommandes.length,
        itemBuilder: (context, index) {
          final commande = _filteredCommandes[index];
          return _buildCommandeCard(commande);
        },
      ),
    );
  }

  Widget _buildCommandeCard(Commande commande) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showCommandeDetails(commande),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${commande.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CommandeViewFactory.buildStatusChip(commande.statut),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Date de commande
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Commandée le ${_formatDate(commande.createdAt)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Articles
              Text(
                '${commande.items.length} article(s)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              
              const SizedBox(height: 4),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:'),
                  Text(
                    '${commande.totalTTC.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Informations de paiement si disponible
              if (commande.paymentInfo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      commande.paymentInfo!.cardDisplay,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              
              // Actions rapides
              const SizedBox(height: 12),
              _buildQuickActions(commande),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(Commande commande) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Vérifier le paiement
        ElevatedButton.icon(
          onPressed: () => _verifyPayment(commande),
          icon: const Icon(Icons.verified_user, size: 16),
          label: const Text('Vérifier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        
        // Actions selon le statut
        if (commande.statut == 'paid')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'confirmed'),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Confirmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        
        if (commande.statut == 'confirmed')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'preparing'),
            icon: const Icon(Icons.restaurant, size: 16),
            label: const Text('Préparer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        
        if (commande.statut == 'preparing')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'ready'),
            icon: const Icon(Icons.done, size: 16),
            label: const Text('Prête'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        
        if (commande.statut == 'ready')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'delivered'),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('Livrée'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  void _showCommandeDetails(Commande commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${commande.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CommandeViewFactory.buildStatusChip(commande.statut),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
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
                              const Text(
                                'Informations générales',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Date de commande', _formatDate(commande.createdAt)),
                              _buildInfoRow('Dernière mise à jour', _formatDate(commande.updatedAt)),
                              if (commande.lastStatusChangeAt != null)
                                _buildInfoRow('Dernier changement', _formatDate(commande.lastStatusChangeAt!)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Articles
                      CommandeViewFactory.buildItemsList(commande.items),
                      
                      const SizedBox(height: 16),
                      
                      // Totaux
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détail des totaux',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Sous-total HT', '${commande.totalHT.toStringAsFixed(2)} €'),
                              _buildInfoRow('TVA (${commande.tvaRate}%)', '${commande.totalTVA.toStringAsFixed(2)} €'),
                              const Divider(),
                              _buildInfoRow(
                                'Total TTC',
                                '${commande.totalTTC.toStringAsFixed(2)} €',
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Informations de paiement
                      CommandeViewFactory.buildPaymentInfo(commande.paymentInfo),
                      
                      const SizedBox(height: 16),
                      
                      // Informations de livraison
                      CommandeViewFactory.buildDeliveryInfo(commande.deliveryInfo),
                      
                      if (commande.notes != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(commande.notes!),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Actions du restaurateur
                      CommandeViewFactory.buildRestaurateurActions(
                        commande: commande,
                        onStatusUpdate: (status) => _updateStatus(commande, status),
                        onVerifyPayment: () => _verifyPayment(commande),
                        onMarkSuspicious: (reason) => _markAsSuspicious(commande, reason),
                        onCancel: (reason) => _cancelCommande(commande, reason),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusDisplayName(String status) {
    final commande = Commande(
      id: 0,
      restaurantId: 0,
      statut: status,
      currency: 'EUR',
      totalHT: 0,
      totalTVA: 0,
      totalTTC: 0,
      tvaRate: 10,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return commande.statusDisplayName;
  }
}
