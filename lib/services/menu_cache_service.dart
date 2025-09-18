import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu.dart';
import 'api_service.dart';

class MenuCacheService {
  static final MenuCacheService _instance = MenuCacheService._internal();
  factory MenuCacheService() => _instance;
  MenuCacheService._internal();

  // Cache en mémoire des menus
  List<Menu> _cachedMenus = [];
  DateTime? _lastUpdate;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Vérifier si le cache est valide
  bool get isCacheValid {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < _cacheValidity;
  }

  // Obtenir les menus (depuis le cache si valide, sinon depuis l'API)
  Future<List<Menu>> getMenus() async {
    if (isCacheValid) {
      print('📋 MenuCacheService: Utilisation du cache (${_cachedMenus.length} menus)');
      return _cachedMenus;
    }

    print('🔄 MenuCacheService: Chargement depuis l\'API');
    final apiService = ApiService();
    
    try {
      _cachedMenus = await apiService.getMenus();
      _lastUpdate = DateTime.now();
      
      print('✅ MenuCacheService: Cache mis à jour (${_cachedMenus.length} menus)');
      
      // Debug: afficher les détails des premiers menus
      for (int i = 0; i < _cachedMenus.length && i < 3; i++) {
        final menu = _cachedMenus[i];
        print('🍽️  Menu ${i + 1}: "${menu.titre}"');
        print('   - Description: ${menu.description}');
        print('   - Allergènes: ${menu.allergenes}');
        print('   - Produits: ${menu.produits}');
        print('   - Prix: ${menu.prix}');
      }
      
      return _cachedMenus;
    } catch (e) {
      print('❌ MenuCacheService: Erreur lors du chargement des menus: $e');
      return [];
    }
  }

  // Mettre à jour un menu dans le cache
  void updateMenuInCache(Menu updatedMenu) {
    final index = _cachedMenus.indexWhere((menu) => menu.id == updatedMenu.id);
    if (index != -1) {
      // Préserver l'ordre en remplaçant à la même position
      _cachedMenus[index] = updatedMenu;
      _lastUpdate = DateTime.now();
      print('✅ MenuCacheService: Menu ${updatedMenu.id} mis à jour dans le cache à la position $index');
    } else {
      // Ajouter à la fin si le menu n'existe pas
      _cachedMenus.add(updatedMenu);
      _lastUpdate = DateTime.now();
      print('✅ MenuCacheService: Menu ${updatedMenu.id} ajouté au cache');
    }
  }

  // Supprimer un menu du cache
  void removeMenuFromCache(int menuId) {
    _cachedMenus.removeWhere((menu) => menu.id == menuId);
    _lastUpdate = DateTime.now();
    print('🗑️ MenuCacheService: Menu $menuId supprimé du cache');
  }

  // Vider le cache
  void clearCache() {
    _cachedMenus.clear();
    _lastUpdate = null;
    print('🧹 MenuCacheService: Cache vidé');
  }

  // Forcer le rafraîchissement du cache
  Future<List<Menu>> refreshCache() async {
    clearCache();
    return await getMenus();
  }
}

// Provider pour le service de cache
final menuCacheServiceProvider = Provider<MenuCacheService>((ref) {
  return MenuCacheService();
});

// Provider pour les menus avec cache intelligent
final cachedMenusProvider = FutureProvider<List<Menu>>((ref) async {
  final cacheService = ref.read(menuCacheServiceProvider);
  return await cacheService.getMenus();
});

// Provider pour forcer le rafraîchissement du cache
final menuCacheRefreshProvider = StateProvider<int>((ref) => 0);

// Provider pour les menus avec rafraîchissement automatique
final smartMenusProvider = FutureProvider<List<Menu>>((ref) async {
  // Écouter le provider de rafraîchissement
  ref.watch(menuCacheRefreshProvider);
  
  final cacheService = ref.read(menuCacheServiceProvider);
  return await cacheService.getMenus();
});
