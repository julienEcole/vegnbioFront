import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

// Provider pour le service API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider pour la liste des restaurants
final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
      // print('🚨🚨🚨 [restaurantsProvider] APPELÉ ! 🚨🚨🚨');
  // debugPrint('🚨🚨🚨 [restaurantsProvider] APPELÉ ! 🚨🚨🚨');
  
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRestaurants();
});

// Provider pour un restaurant spécifique
final restaurantProvider = FutureProvider.family<Restaurant, int>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRestaurant(id);
});

// Provider pour l'état de connexion à l'API
final apiHealthProvider = FutureProvider<bool>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.checkApiHealth();
});
