import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/menu/public_menu_view.dart';
import '../../providers/auth_provider.dart';
import '../../utils/web_logger.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  MenuScreen({super.key, this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[MenuScreen] BUILD APPELÉ !', '🍽️', color: '#4CAF50');
    
    final authState = ref.watch(authProvider);
    
    // Si l'utilisateur est authentifié, afficher une vue différente
    if (authState.isAuthenticated) {
      WebLogger.logWithEmoji('[MenuScreen] Utilisateur authentifié: ${authState.role}', '👤', color: '#4CAF50');
      
      // Pour l'instant, on affiche la même vue mais avec des fonctionnalités supplémentaires
      // TODO: Créer une vue spécifique pour les clients authentifiés
      return PublicMenuView(restaurantId: widget.restaurantId);
    }
    
    // Vue publique pour les utilisateurs non authentifiés
    WebLogger.logWithEmoji('[MenuScreen] Utilisateur non authentifié', '👤', color: '#FF9800');
    return PublicMenuView(restaurantId: widget.restaurantId);
  }
}