import 'package:flutter/material.dart';
import '../../models/commande.model.dart';
import '../../services/commande.service.dart';
import '../../factories/commande_view_factory.dart';

class ClientOrdersScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const ClientOrdersScreen({
    Key? key,
    required this.userId,
    this.token,
  }) : super(key: key);

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  List<Commande> _commandes = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  int _total = 0;
  int _offset = 0;
  final int _limit = 20;

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
  ];

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _commandes.clear();
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await CommandeService.getUserCommandes(
        userId: widget.userId,
        status: _selectedStatus == 'Tous' ? null : _selectedStatus,
        limit: _limit,
        offset: _offset,
        token: widget.token,
      );

      if (result['success']) {
        setState(() {
          if (refresh) {
            _commandes = result['commandes'];
          } else {
            _commandes.addAll(result['commandes']);
          }
          _total = result['total'];
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

  Future<void> _loadMore() async {
    if (_commandes.length < _total && !_isLoading) {
      setState(() {
        _offset += _limit;
      });
      await _loadCommandes();
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadCommandes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: Colors.green,
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
          // Filtre par statut
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filtrer par statut',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status == 'Tous' ? 'Tous les statuts' : _getStatusDisplayName(status)),
                );
              }).toList(),
              onChanged: _onStatusFilterChanged,
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
    if (_isLoading && _commandes.isEmpty) {
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

    if (_commandes.isEmpty) {
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: _commandes.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _commandes.length) {
              // Indicateur de chargement en bas
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final commande = _commandes[index];
            return _buildCommandeCard(commande);
          },
        ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showCommandeDetails(Commande commande) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar pour indiquer que c'est draggable
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Contenu avec padding minimal en haut
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    ],
                  ),
                ),
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
