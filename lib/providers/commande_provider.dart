import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commande.dart';
import '../models/commande_item.dart';
import '../services/api_service.dart';

// Provider pour le service API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider pour la liste des commandes
final commandesProvider = FutureProvider<List<Commande>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCommandes();
});

// Provider pour une commande spécifique
final commandeProvider = FutureProvider.family<Commande, int>((ref, id) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCommandeById(id);
});

// Provider pour l'état de création/modification de commande
class CommandeNotifier extends StateNotifier<AsyncValue<Commande?>> {
  CommandeNotifier(this._apiService) : super(const AsyncValue.data(null));

  final ApiService _apiService;

  // Créer une nouvelle commande
  Future<void> createCommande({
    required int restaurantId,
    List<CommandeItem> items = const [],
    String currency = 'EUR',
    double tvaRate = 10.0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final commande = await _apiService.createCommande(
        restaurantId: restaurantId,
        items: items,
        currency: currency,
        tvaRate: tvaRate,
      );
      state = AsyncValue.data(commande);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Mettre à jour le statut d'une commande
  Future<void> updateStatut(int id, String statut) async {
    state = const AsyncValue.loading();
    try {
      final commande = await _apiService.updateCommandeStatut(id, statut);
      state = AsyncValue.data(commande);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Remplacer les items d'une commande
  Future<void> replaceItems(int id, List<CommandeItem> items) async {
    state = const AsyncValue.loading();
    try {
      final commande = await _apiService.replaceCommandeItems(id, items);
      state = AsyncValue.data(commande);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Charger une commande par ID
  Future<void> loadCommande(int id) async {
    state = const AsyncValue.loading();
    try {
      final commande = await _apiService.getCommandeById(id);
      state = AsyncValue.data(commande);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Réinitialiser l'état
  void reset() {
    state = const AsyncValue.data(null);
  }
}

final commandeNotifierProvider = StateNotifierProvider<CommandeNotifier, AsyncValue<Commande?>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return CommandeNotifier(apiService);
});

// Provider pour les statistiques de commandes
final commandesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final commandes = await ref.watch(commandesProvider.future);
  
  final stats = <String, dynamic>{
    'total': commandes.length,
    'draft': commandes.where((c) => c.statut == CommandeStatut.draft).length,
    'pending': commandes.where((c) => c.statut == CommandeStatut.pending).length,
    'paid': commandes.where((c) => c.statut == CommandeStatut.paid).length,
    'cancelled': commandes.where((c) => c.statut == CommandeStatut.cancelled).length,
    'refunded': commandes.where((c) => c.statut == CommandeStatut.refunded).length,
    'totalRevenue': commandes
        .where((c) => c.statut == CommandeStatut.paid)
        .fold(0.0, (sum, c) => sum + c.totalTTC),
    'averageOrderValue': commandes
        .where((c) => c.statut == CommandeStatut.paid)
        .isEmpty ? 0.0 : commandes
        .where((c) => c.statut == CommandeStatut.paid)
        .fold(0.0, (sum, c) => sum + c.totalTTC) / 
        commandes.where((c) => c.statut == CommandeStatut.paid).length,
  };
  
  return stats;
});
