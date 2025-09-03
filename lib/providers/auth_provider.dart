import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';


class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final role = await _authService.getUserRole();
        final userId = await _authService.getUserId();
        
        state = AuthState.authenticated(
          role: role ?? 'client',
          userId: userId ?? 0,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        final role = result['role'] as String;
        final userId = result['userId'] as int;
        
        state = AuthState.authenticated(
          role: role,
          userId: userId,
        );
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
        // Après inscription réussie, on reste en état non authentifié
        // L'utilisateur doit se connecter
        state = const AuthState.unauthenticated();
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
