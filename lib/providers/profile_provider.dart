import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_state_provider.dart';

/// État du profil utilisateur
class ProfileState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? profile;
  final bool isUpdating;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.isUpdating = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? profile,
    bool? isUpdating,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

/// Provider pour la gestion du profil utilisateur
class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthService _authService;
  final Ref _ref;

  ProfileNotifier(this._authService, this._ref) : super(const ProfileState()) {
    print('👤 [ProfileProvider] Initialisation...');
    _loadProfile();
  }

  /// Charger le profil utilisateur
  Future<void> _loadProfile() async {
    print('👤 [ProfileProvider] ===== DÉBUT _loadProfile() =====');
    
    // Vérifier si l'utilisateur est authentifié
    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      print('👤 [ProfileProvider] ❌ Utilisateur non authentifié');
      state = state.copyWith(
        isLoading: false,
        error: 'Utilisateur non authentifié',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('👤 [ProfileProvider] Récupération profil...');
      final profile = await _authService.getUserProfile();
      
      if (profile != null) {
        print('👤 [ProfileProvider] ✅ Profil chargé: ${profile['nom'] ?? 'N/A'}');
        state = state.copyWith(
          isLoading: false,
          profile: profile,
        );
      } else {
        print('👤 [ProfileProvider] ❌ Profil non trouvé');
        state = state.copyWith(
          isLoading: false,
          error: 'Profil non trouvé',
        );
      }
    } catch (e) {
      print('👤 [ProfileProvider] ❌ Erreur chargement profil: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    print('👤 [ProfileProvider] ===== DÉBUT updateProfile() =====');
    print('👤 [ProfileProvider] Mises à jour: $updates');
    
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // Simuler un appel API pour la mise à jour
      // TODO: Remplacer par un vrai appel API
      await Future.delayed(const Duration(seconds: 1));
      
      // Mettre à jour le profil localement
      final currentProfile = state.profile ?? {};
      final updatedProfile = {...currentProfile, ...updates};
      
      print('👤 [ProfileProvider] ✅ Profil mis à jour');
      state = state.copyWith(
        isUpdating: false,
        profile: updatedProfile,
      );

      // Mettre à jour l'AuthState aussi
      _ref.read(authStateProvider.notifier).updateProfile(updatedProfile);
      
      return true;
    } catch (e) {
      print('👤 [ProfileProvider] ❌ Erreur mise à jour: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Rafraîchir le profil
  Future<void> refresh() async {
    print('👤 [ProfileProvider] Rafraîchissement profil...');
    await _loadProfile();
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    print('👤 [ProfileProvider] ===== DÉBUT changePassword() =====');
    
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // TODO: Implémenter le changement de mot de passe via l'API
      await Future.delayed(const Duration(seconds: 1));
      
      print('👤 [ProfileProvider] ✅ Mot de passe changé');
      state = state.copyWith(isUpdating: false);
      
      return true;
    } catch (e) {
      print('👤 [ProfileProvider] ❌ Erreur changement mot de passe: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Supprimer le compte
  Future<bool> deleteAccount() async {
    print('👤 [ProfileProvider] ===== DÉBUT deleteAccount() =====');
    
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // TODO: Implémenter la suppression du compte via l'API
      await Future.delayed(const Duration(seconds: 1));
      
      print('👤 [ProfileProvider] ✅ Compte supprimé');
      
      // Déconnecter l'utilisateur
      await _ref.read(authStateProvider.notifier).logout();
      
      return true;
    } catch (e) {
      print('👤 [ProfileProvider] ❌ Erreur suppression compte: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// Provider principal pour le profil utilisateur
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(AuthService(), ref);
});

/// Provider pour vérifier si le profil est chargé
final isProfileLoadedProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile != null && !profileState.isLoading;
});

/// Provider pour récupérer les informations de base du profil
final profileInfoProvider = Provider<Map<String, String>>((ref) {
  final profileState = ref.watch(profileProvider);
  final profile = profileState.profile ?? {};
  
  return {
    'nom': profile['nom'] ?? 'N/A',
    'email': profile['email'] ?? 'N/A',
    'role': profile['role'] ?? 'client',
    'telephone': profile['telephone'] ?? 'N/A',
  };
});
