import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/simple_auth_service.dart';

// États d'authentification simplifiés
enum SimpleAuthStatus { unauthenticated, authenticated, loading, error }

class SimpleAuthState {
  final SimpleAuthStatus status;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  const SimpleAuthState({
    this.status = SimpleAuthStatus.unauthenticated,
    this.userData,
    this.errorMessage,
  });

  const SimpleAuthState.unauthenticated() : this(status: SimpleAuthStatus.unauthenticated);
  const SimpleAuthState.authenticated(Map<String, dynamic> userData) : this(
    status: SimpleAuthStatus.authenticated,
    userData: userData,
  );
  const SimpleAuthState.loading() : this(status: SimpleAuthStatus.loading);
  const SimpleAuthState.error(String message) : this(
    status: SimpleAuthStatus.error,
    errorMessage: message,
  );

  bool get isAuthenticated => status == SimpleAuthStatus.authenticated;
  bool get isLoading => status == SimpleAuthStatus.loading;
  bool get hasError => status == SimpleAuthStatus.error;
  String? get userRole => userData?['role'];
  String? get role => userData?['role'];
}

class SimpleAuthNotifier extends StateNotifier<SimpleAuthState> {
  final SimpleAuthService _authService = SimpleAuthService();
  bool _isInitialized = false;

  SimpleAuthNotifier() : super(const SimpleAuthState.unauthenticated()) {
    print('🏁 [SimpleAuthNotifier] Initialisation - État: non authentifié');
    // Ne pas initialiser automatiquement - sera fait quand nécessaire
  }

  /// Initialiser le service d'authentification seulement quand nécessaire
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    print('🔍 [SimpleAuthNotifier] Initialisation du service...');
    state = const SimpleAuthState.loading();
    
    try {
      await _authService.initialize();
      
      if (_authService.isLoggedIn && _authService.userData != null) {
        print('✅ [SimpleAuthNotifier] Utilisateur connecté');
        state = SimpleAuthState.authenticated(_authService.userData!);
      } else {
        print('🌐 [SimpleAuthNotifier] Utilisateur non connecté');
        state = const SimpleAuthState.unauthenticated();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur d\'initialisation: $e');
      state = SimpleAuthState.error(e.toString());
      _isInitialized = true;
    }
  }

  /// Connexion
  Future<bool> login(String email, String password) async {
    print('🔐 [SimpleAuthNotifier] Tentative de connexion: $email');
    await _ensureInitialized(); // Initialiser si nécessaire
    state = const SimpleAuthState.loading();

    try {
      final success = await _authService.login(email, password);
      
      if (success && _authService.userData != null) {
        print('✅ [SimpleAuthNotifier] Connexion réussie');
        state = SimpleAuthState.authenticated(_authService.userData!);
        return true;
      } else {
        print('❌ [SimpleAuthNotifier] Échec de la connexion');
        state = const SimpleAuthState.error('Échec de la connexion');
        return false;
      }
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur lors de la connexion: $e');
      state = SimpleAuthState.error(e.toString());
      return false;
    }
  }

  /// Inscription
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String nameRole,
  }) async {
    print('📝 [SimpleAuthNotifier] Tentative d\'inscription: $email');
    await _ensureInitialized(); // Initialiser si nécessaire
    state = const SimpleAuthState.loading();

    try {
      final success = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        nameRole: nameRole,
      );
      
      if (success && _authService.userData != null) {
        print('✅ [SimpleAuthNotifier] Inscription réussie');
        state = SimpleAuthState.authenticated(_authService.userData!);
        return true;
      } else {
        print('❌ [SimpleAuthNotifier] Échec de l\'inscription');
        state = const SimpleAuthState.error('Échec de l\'inscription');
        return false;
      }
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur lors de l\'inscription: $e');
      state = SimpleAuthState.error(e.toString());
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    print('🚪 [SimpleAuthNotifier] Déconnexion...');
    await _ensureInitialized(); // Initialiser si nécessaire
    
    try {
      await _authService.logout();
      state = const SimpleAuthState.unauthenticated();
      print('✅ [SimpleAuthNotifier] Déconnexion réussie');
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur lors de la déconnexion: $e');
      state = SimpleAuthState.error(e.toString());
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    print('📝 [SimpleAuthNotifier] Mise à jour du profil...');
    await _ensureInitialized(); // Initialiser si nécessaire
    
    try {
      final success = await _authService.updateProfile(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
      );
      
      if (success && _authService.userData != null) {
        state = SimpleAuthState.authenticated(_authService.userData!);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur lors de la mise à jour: $e');
      state = SimpleAuthState.error(e.toString());
      return false;
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    print('🔐 [SimpleAuthNotifier] Changement du mot de passe...');
    await _ensureInitialized(); // Initialiser si nécessaire
    
    try {
      return await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      print('❌ [SimpleAuthNotifier] Erreur lors du changement de mot de passe: $e');
      state = SimpleAuthState.error(e.toString());
      return false;
    }
  }

  /// Vérifier l'état d'authentification (pour la navigation)
  Future<void> checkAuthStatus() async {
    await _ensureInitialized(); // Initialiser si nécessaire
  }
}

// Provider principal simplifié
final simpleAuthProvider = StateNotifierProvider<SimpleAuthNotifier, SimpleAuthState>((ref) {
  return SimpleAuthNotifier();
});

// Providers dérivés pour faciliter l'utilisation
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(simpleAuthProvider).isAuthenticated;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(simpleAuthProvider).userRole;
});

final userDataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(simpleAuthProvider).userData;
});
