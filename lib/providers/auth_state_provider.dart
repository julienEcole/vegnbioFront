import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// État d'authentification unifié
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userRole;
  final int? userId;
  final String? error;
  final Map<String, dynamic>? userProfile;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.userRole,
    this.userId,
    this.error,
    this.userProfile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userRole,
    int? userId,
    String? error,
    Map<String, dynamic>? userProfile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      error: error ?? this.error,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

/// Provider pour l'état d'authentification unifié
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AuthState()) {
    print('🔐 [AuthStateProvider] Initialisation...');
    print('🔐 [AuthStateProvider] ===== CONSTRUCTEUR APPELÉ =====');
    _initializeAuth();
  }

  /// Initialiser l'état d'authentification
  Future<void> _initializeAuth() async {
    print('🔐 [AuthStateProvider] ===== DÉBUT _initializeAuth() =====');
    
    try {
      // Vérifier si l'utilisateur est connecté
      final hasToken = await _authService.isLoggedIn();
      print('🔐 [AuthStateProvider] Token présent: $hasToken');
      
      if (!hasToken) {
        print('🔐 [AuthStateProvider] ❌ Aucun token → Non authentifié');
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
        return;
      }

      // Récupérer le profil utilisateur
      print('🔐 [AuthStateProvider] Récupération profil...');
      final userProfile = await _authService.getUserProfile();
      
      if (userProfile != null) {
        final role = userProfile['role'] ?? 'client';
        final userId = userProfile['id'] ?? 0;
        
        print('🔐 [AuthStateProvider] ✅ Authentifié - Rôle: $role, UserId: $userId');
        print('🔐 [AuthStateProvider] 📋 Profil complet: $userProfile');
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          userRole: role,
          userId: userId,
          userProfile: userProfile,
        );
        print('🔐 [AuthStateProvider] ✅ État mis à jour avec userProfile');
      } else {
        // Fallback vers les données locales
        print('🔐 [AuthStateProvider] Fallback vers données locales...');
        final localRole = await _authService.getUserRole();
        final localUserId = await _authService.getUserId();
        
        if (localRole != null && localUserId != null) {
          print('🔐 [AuthStateProvider] ✅ Données locales - Rôle: $localRole, UserId: $localUserId');
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            userRole: localRole,
            userId: localUserId,
          );
        } else {
          print('🔐 [AuthStateProvider] ❌ Données incomplètes → Non authentifié');
          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            error: 'Données utilisateur incomplètes',
          );
        }
      }
    } catch (e) {
      print('🔐 [AuthStateProvider] ❌ Erreur: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Se connecter
  Future<bool> login(String email, String password) async {
    print('🔐 [AuthStateProvider] Tentative de connexion...');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.login(email, password);
      
      // Vérifier le résultat selon le type retourné par AuthService
      bool success = (result['success'] as bool?) ?? false;
      
      if (success) {
        print('🔐 [AuthStateProvider] ✅ Connexion réussie');
        await _initializeAuth(); // Recharger les données
        return true;
      } else {
        print('🔐 [AuthStateProvider] ❌ Connexion échouée');
        state = state.copyWith(
          isLoading: false,
          error: 'Identifiants incorrects',
        );
        return false;
      }
    } catch (e) {
      print('🔐 [AuthStateProvider] ❌ Erreur connexion: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Se déconnecter
  Future<void> logout() async {
    print('🔐 [AuthStateProvider] Déconnexion...');
    
    try {
      await _authService.logout();
      print('🔐 [AuthStateProvider] ✅ Déconnexion réussie');
      
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      print('🔐 [AuthStateProvider] ❌ Erreur déconnexion: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Rafraîchir l'état d'authentification
  Future<void> refresh() async {
    print('🔐 [AuthStateProvider] Rafraîchissement...');
    await _initializeAuth();
  }

  /// Mettre à jour le profil utilisateur
  void updateProfile(Map<String, dynamic> newProfile) {
    print('🔐 [AuthStateProvider] Mise à jour profil...');
    state = state.copyWith(userProfile: newProfile);
  }
}

/// Provider principal pour l'état d'authentification
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(AuthService());
});

/// Provider pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// Provider pour récupérer le rôle de l'utilisateur
final userRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.userRole;
});

/// Provider pour récupérer le profil utilisateur
final userProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.userProfile;
});