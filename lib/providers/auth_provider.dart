import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';


class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('🔍 [AuthProvider] Vérification du statut d\'authentification...');
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        print('🔍 [AuthProvider] Token détecté, vérification avec l\'API...');
        
        // Vérifier le token avec le backend et récupérer le profil
        final profile = await _authService.getUserProfile();
        
        if (profile != null) {
          final role = (profile['role'] as String?)?.toLowerCase() ?? '';
          final userId = profile['id'] as int? ?? 0;
          
          print('✅ [AuthProvider] Profil validé depuis l\'API: $role, ID: $userId');
          
          state = AuthState.authenticated(
            role: role.isEmpty ? (await _authService.getUserRole() ?? 'client') : role,
            userId: userId == 0 ? (await _authService.getUserId() ?? 0) : userId,
          );
        } else {
          print('🔄 [AuthProvider] Token invalide ou API indisponible, utilisation du fallback...');
          // Fallback: utiliser les données stockées localement
          final role = await _authService.getUserRole();
          final userId = await _authService.getUserId();
          
          if (role != null && userId != null) {
            state = AuthState.authenticated(
              role: role,
              userId: userId,
            );
          } else {
            // Token invalide, déconnecter
            await _authService.logout();
            state = const AuthState.unauthenticated();
          }
        }
      } else {
        print('🔍 [AuthProvider] Aucun token détecté');
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      print('❌ [AuthProvider] Erreur lors de la vérification: $e');
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        print('✅ [AuthProvider] Connexion réussie, récupération du profil...');
        
        // Après connexion réussie, récupérer le profil depuis l'API
        final profile = await _authService.getUserProfile();
        
        if (profile != null) {
          final role = (profile['role'] as String?)?.toLowerCase() ?? '';
          final userId = profile['id'] as int? ?? 0;
          
          print('✅ [AuthProvider] Profil récupéré depuis l\'API: $role, ID: $userId');
          
          state = AuthState.authenticated(
            role: role.isEmpty ? (result['role'] as String) : role,
            userId: userId == 0 ? (result['userId'] as int) : userId,
          );
        } else {
          print('🔄 [AuthProvider] Fallback vers données du token');
          // Fallback: utiliser les données du token si l'API échoue
          final role = result['role'] as String;
          final userId = result['userId'] as int;
          
          state = AuthState.authenticated(
            role: role,
            userId: userId,
          );
        }
      } else {
        state = AuthState.error(result['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String nameRole = 'client',
  }) async {
    state = const AuthState.loading();

    try {
      final result = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        nameRole: nameRole,
      );
      
      if (result['success'] == true) {
        // Après inscription réussie, si un token est retourné, connecter automatiquement l'utilisateur
        if (result['token'] != null) {
          final role = result['role'] as String;
          final userId = result['userId'] as int;
          
          state = AuthState.authenticated(
            role: role,
            userId: userId,
          );
        } else {
          // Si pas de token, rester en état non authentifié
          state = const AuthState.unauthenticated();
        }
      } else {
        state = AuthState.error(result['message'] ?? 'Erreur d\'inscription');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> refreshAuthStatus() async {
    await _checkAuthStatus();
  }

  bool get isAuthenticated => state is AuthenticatedAuthState;
  bool get isLoading => state is LoadingAuthState;
  bool get hasError => state is ErrorAuthState;
  
  String? get userRole {
    if (state is AuthenticatedAuthState) {
      return (state as AuthenticatedAuthState).role;
    }
    return null;
  }
  
  int? get userId {
    if (state is AuthenticatedAuthState) {
      return (state as AuthenticatedAuthState).userId;
    }
    return null;
  }

  bool hasRole(String role) {
    return userRole == role;
  }

  bool hasAnyRole(List<String> roles) {
    final currentRole = userRole;
    return currentRole != null && roles.contains(currentRole);
  }
}

// États d'authentification
abstract class AuthState {
  const AuthState();
  
  // Constructeurs factory pour créer les différents états
  const factory AuthState.initial() = InitialAuthState;
  const factory AuthState.loading() = LoadingAuthState;
  const factory AuthState.authenticated({required String role, required int userId}) = AuthenticatedAuthState;
  const factory AuthState.unauthenticated() = UnauthenticatedAuthState;
  const factory AuthState.error(String message) = ErrorAuthState;
}

class InitialAuthState extends AuthState {
  const InitialAuthState();
}

class LoadingAuthState extends AuthState {
  const LoadingAuthState();
}

class AuthenticatedAuthState extends AuthState {
  final String role;
  final int userId;

  const AuthenticatedAuthState({
    required this.role,
    required this.userId,
  });
}

class UnauthenticatedAuthState extends AuthState {
  const UnauthenticatedAuthState();
}

class ErrorAuthState extends AuthState {
  final String message;

  const ErrorAuthState(this.message);
}

// Provider principal
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

// Providers dérivés pour faciliter l'accès
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return ref.read(authProvider.notifier);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.notifier).isAuthenticated;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.notifier).userRole;
});

final userIdProvider = Provider<int?>((ref) {
  return ref.watch(authProvider.notifier).userId;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.notifier).isLoading;
});

final hasErrorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.notifier).hasError;
});
