import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/panier_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/commande_provider.dart';
import '../services/api_service.dart';
import '../models/commande_item.dart';
import '../widgets/panier/panier_summary_widget.dart';

class CheckoutAuthenticatedScreen extends ConsumerStatefulWidget {
  const CheckoutAuthenticatedScreen({super.key});

  @override
  ConsumerState<CheckoutAuthenticatedScreen> createState() => _CheckoutAuthenticatedScreenState();
}

class _CheckoutAuthenticatedScreenState extends ConsumerState<CheckoutAuthenticatedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _commentairesController = TextEditingController();
  
  int? _selectedRestaurantId;
  String _modePaiement = 'especes';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      _nomController.text = user.nom;
      _emailController.text = user.email;
      _telephoneController.text = user.telephone ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panier = ref.watch(panierProvider);
    final stats = ref.watch(panierStatsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _buildNotAuthenticated();
          }
          return _buildCheckoutForm(panier, stats);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotAuthenticated() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Authentification requise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous devez être connecté pour finaliser votre commande.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Se connecter',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(List<dynamic> panier, Map<String, dynamic> stats) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la commande
            PanierSummaryWidget(stats: stats),
            
            const SizedBox(height: 24),
            
            // Informations de livraison
            Text(
              'Informations de livraison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre nom';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre email';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre téléphone';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse de livraison',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre adresse';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Restaurant
            Text(
              'Restaurant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<int>(
              value: _selectedRestaurantId,
              decoration: const InputDecoration(
                labelText: 'Sélectionner un restaurant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Restaurant Bastille')),
                DropdownMenuItem(value: 2, child: Text('Restaurant République')),
                DropdownMenuItem(value: 3, child: Text('Restaurant Nation')),
                DropdownMenuItem(value: 4, child: Text('Restaurant Italie')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRestaurantId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un restaurant';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Mode de paiement
            Text(
              'Mode de paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _modePaiement,
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                DropdownMenuItem(value: 'carte', child: Text('Carte bancaire')),
                DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
              ],
              onChanged: (value) {
                setState(() {
                  _modePaiement = value!;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Commentaires
            TextFormField(
              controller: _commentairesController,
              decoration: const InputDecoration(
                labelText: 'Commentaires (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de commande
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _passerCommande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmer la commande',
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

  Future<void> _passerCommande() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final panier = ref.read(panierProvider);
      final commandeItems = panier.map((item) => item.toCommandeItemJson()).toList();
      
      final apiService = ApiService();
      final commande = await apiService.createCommande(
        restaurantId: _selectedRestaurantId!,
        items: commandeItems.map((item) => CommandeItem.fromJson(item)).toList(),
      );

      // Vider le panier
      ref.read(panierProvider.notifier).viderPanier();

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande #${commande.id} créée avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Naviguer vers la page de confirmation
        Navigator.pushReplacementNamed(context, '/commande-confirmation', arguments: commande);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la commande: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
