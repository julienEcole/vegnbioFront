import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/restaurant/public_restaurant_view.dart';
import '../../providers/auth_provider.dart';
import '../../utils/web_logger.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  final int? highlightRestaurantId;
  
  const RestaurantsScreen({super.key, this.highlightRestaurantId});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[RestaurantsScreen] BUILD APPELÉ !', '🏪', color: '#FF5722');
    
    final authState = ref.watch(authProvider);
    
    // Si l'utilisateur est authentifié, afficher une vue différente
    if (authState.isAuthenticated) {
      WebLogger.logWithEmoji('[RestaurantsScreen] Utilisateur authentifié: ${authState.role}', '👤', color: '#4CAF50');
      
      // Pour l'instant, on affiche la même vue mais avec des fonctionnalités supplémentaires
      // TODO: Créer une vue spécifique pour les clients authentifiés
      return PublicRestaurantView(highlightRestaurantId: widget.highlightRestaurantId);
    }
    
    // Vue publique pour les utilisateurs non authentifiés
    WebLogger.logWithEmoji('[RestaurantsScreen] Utilisateur non authentifié', '👤', color: '#FF9800');
    return PublicRestaurantView(highlightRestaurantId: widget.highlightRestaurantId);
  }
}