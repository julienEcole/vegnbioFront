import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth/real_auth_service.dart';
import '../config/app_config.dart';

// États d'authentification
enum AuthStatus { unauthenticated, authenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userData,
    this.errorMessage,
  });

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(Map<String, dynamic> userData)
      : this(status: AuthStatus.authenticated, userData: userData);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  // --- EXISTANT (inchangé) ---
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  // Ces deux getters existent déjà dans votre base: on les garde pour compat.
  String? get userRole => userData?['role'];
  String? get role => userData?['role'];

  // --- AJOUTS NON-RUPTURE pour "offres" ---

  /// Rôle "effectif" plus robuste (si le back envoie d'autres clés)
  String? get effectiveRole {
    final r = userData?['role'] ??
        userData?['nameRole'] ??
        userData?['profil']?['role'];
    return r?.toString();
  }

  /// ID utilisateur (tolérant: id | userId | _id, string ou int)
  int? get userId {
    final v = userData?['id'] ?? userData?['userId'] ?? userData?['_id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Alias clair pour lier une offre à son propriétaire côté client
  int? get fournisseurId => userId;

  // alias pour compat avec le code existant (offres_provider.dart lit me.id)
  int? get id => userId;

  /// Email utilisateur (tolérant sur la clé)
  String? get email => userData?['email'] ?? userData?['mail'];

  /// Token actuel (conservé dans le service)
  String? get token => RealAuthService().token;

  /// Helpers pratiques pour les gardes d’accès
  bool get isFournisseur => (effectiveRole?.toLowerCase() == 'fournisseur');
  bool get isAdmin => (effectiveRole?.toLowerCase() == 'admin');
}

class AuthNotifier extends StateNotifier<AuthState> {
  final RealAuthService _authService = RealAuthService();
  bool _isInitialized = false;

  AuthNotifier() : super(const AuthState.unauthenticated()) {
    print('🏁 [AuthNotifier] Initialisation - État: non authentifié');
  }

  /// Initialiser le service d'authentification
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    print('🔍 [RealAuthNotifier] Initialisation du service...');
    state = const AuthState.loading();
    
    try {
      await _authService.initialize();
      
      if (_authService.isLoggedIn && _authService.userData != null) {
        print('✅ [RealAuthNotifier] Utilisateur connecté');
        state = AuthState.authenticated(_authService.userData!);
      } else {
        print('🌐 [RealAuthNotifier] Utilisateur non connecté');
        state = const AuthState.unauthenticated();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur d\'initialisation: $e');
      state = AuthState.error(e.toString());
      _isInitialized = true;
    }
  }

  /// Connexion
  Future<bool> login(String email, String password) async {
    print('🔐 [RealAuthNotifier] Tentative de connexion: $email');
    await _ensureInitialized();
    state = const AuthState.loading();

    try {
      print('📞 [RealAuthNotifier] Appel du service de connexion...');
      final success = await _authService.login(email, password);
      
      if (success && _authService.userData != null) {
        print('✅ [RealAuthNotifier] Connexion réussie');
        state = AuthState.authenticated(_authService.userData!);
        return true;
      } else {
        print('❌ [RealAuthNotifier] Échec de la connexion');
        state = const AuthState.error('Échec de la connexion');
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors de la connexion: $e');
      print('❌ [RealAuthNotifier] Type d\'erreur: ${e.runtimeType}');
      state = AuthState.error(e.toString());
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
    print('📝 [RealAuthNotifier] Tentative d\'inscription: $email');
    await _ensureInitialized();
    state = const AuthState.loading();

    try {
      final success = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        nameRole: nameRole,
      );
      
      if (success && _authService.userData != null) {
        print('✅ [RealAuthNotifier] Inscription réussie');
        state = AuthState.authenticated(_authService.userData!);
        return true;
      } else {
        print('❌ [RealAuthNotifier] Échec de l\'inscription');
        state = const AuthState.error('Échec de l\'inscription');
        return false;
      }
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors de l\'inscription: $e');
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    print('🚪 [RealAuthNotifier] Déconnexion...');
    await _ensureInitialized();
    
    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
      print('✅ [RealAuthNotifier] Déconnexion réussie');
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors de la déconnexion: $e');
      state = AuthState.error(e.toString());
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    String? email,
  }) async {
    print('📝 [RealAuthNotifier] Mise à jour du profil...');
    await _ensureInitialized();
    
    try {
      final success = await _authService.updateProfile(
        nom: nom,
        prenom: prenom,
        email: email,
      );
      
      if (success && _authService.userData != null) {
        state = AuthState.authenticated(_authService.userData!);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors de la mise à jour: $e');
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String newPassword) async {
    print('🔐 [RealAuthNotifier] Changement du mot de passe...');
    await _ensureInitialized();
    
    try {
      return await _authService.changePassword(newPassword);
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors du changement de mot de passe: $e');
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Vérifier l'état d'authentification
  Future<void> checkAuthStatus() async {
    await _ensureInitialized();
  }

  /// Charger le profil complet de l'utilisateur
  Future<bool> loadUserProfile() async {
    print('👤 [RealAuthNotifier] Chargement du profil utilisateur...');
    await _ensureInitialized();
    
    try {
      final success = await _authService.loadUserProfile();
      
      if (success && _authService.userData != null) {
        state = AuthState.authenticated(_authService.userData!);
        print('✅ [RealAuthNotifier] Profil utilisateur chargé avec succès');
        return true;
      }
      
      print('❌ [RealAuthNotifier] Échec du chargement du profil');
      return false;
    } catch (e) {
      print('❌ [RealAuthNotifier] Erreur lors du chargement du profil: $e');
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  Future<bool> hasRole(String role) async {
    await _ensureInitialized();
    return await _authService.hasRole(role);
  }

  /// Vérifier si l'utilisateur peut accéder à des fonctionnalités admin
  bool canAccessAdmin() {
    final role = state.userRole;
    return role != null && AppConfig.adminRoles.contains(role);
  }

  /// Vérifier si l'utilisateur peut accéder à des fonctionnalités restaurateur
  bool canAccessRestaurateur() {
    final role = state.userRole;
    return role != null && AppConfig.restaurateurRoles.contains(role);
  }

  /// Vérifier si l'utilisateur peut accéder à des fonctionnalités fournisseur
  bool canAccessFournisseur() {
    final role = state.userRole;
    return role != null && AppConfig.fournisseurRoles.contains(role);
  }

  /// Vérifier si l'utilisateur peut accéder à des fonctionnalités client
  bool canAccessClient() {
    final role = state.userRole;
    return role != null && AppConfig.clientRoles.contains(role);
  }

  /// Vérifier si l'utilisateur peut accéder à des vues protégées (rôles > client)
  bool canAccessProtectedView() {
    if (!state.isAuthenticated) return false;
    return canAccessRestaurateur() || canAccessFournisseur() || canAccessAdmin();
  }

  /// Vérifier si le token est valide
  Future<bool> verifyToken() async {
    await _ensureInitialized();
    return await _authService.verifyToken();
  }
}

// Provider principal pour l'authentification réelle
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Providers dérivés pour faciliter l'utilisation
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).userRole;
});

final userDataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).userData;
});

// Provider pour vérifier les rôles spécifiques
final hasRoleProvider = Provider.family<bool, String>((ref, role) {
  final authState = ref.watch(authProvider);
  return authState.userRole == role;
});

// Provider pour vérifier si l'utilisateur peut accéder à des vues protégées
final canAccessProtectedViewProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return false;
  
  final role = authState.userRole;
  return role != null && (AppConfig.restaurateurRoles.contains(role) || 
                         AppConfig.fournisseurRoles.contains(role) || 
                         AppConfig.adminRoles.contains(role));
});

// Providers pour vérifier les rôles spécifiques
final canAccessAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.userRole;
  return role != null && AppConfig.adminRoles.contains(role);
});

final canAccessRestaurateurProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.userRole;
  return role != null && AppConfig.restaurateurRoles.contains(role);
});

final canAccessFournisseurProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.userRole;
  return role != null && AppConfig.fournisseurRoles.contains(role);
});

final canAccessClientProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.userRole;
  return role != null && AppConfig.clientRoles.contains(role);
});
