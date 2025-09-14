import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// État de l'inscription
class RegistrationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? successMessage;

  const RegistrationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.successMessage,
  });

  RegistrationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

/// Données d'inscription
class RegistrationData {
  final String nom;
  final String email;
  final String password;
  final String? telephone;
  final String? adresse;

  const RegistrationData({
    required this.nom,
    required this.email,
    required this.password,
    this.telephone,
    this.adresse,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'email': email,
      'password': password,
      if (telephone != null) 'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
    };
  }
}

/// Provider pour la gestion de l'inscription
class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final AuthService _authService;
  final Ref _ref;

  RegistrationNotifier(this._authService, this._ref) : super(const RegistrationState()) {
    print('📝 [RegistrationProvider] Initialisation...');
  }

  /// S'inscrire
  Future<bool> register(RegistrationData data) async {
    print('📝 [RegistrationProvider] ===== DÉBUT register() =====');
    print('📝 [RegistrationProvider] Email: ${data.email}');
    print('📝 [RegistrationProvider] Nom: ${data.nom}');
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
    );

    try {
      // Validation des données
      if (data.email.isEmpty || data.password.isEmpty || data.nom.isEmpty) {
        throw Exception('Tous les champs obligatoires doivent être remplis');
      }

      if (!_isValidEmail(data.email)) {
        throw Exception('Format d\'email invalide');
      }

      if (data.password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }

      print('📝 [RegistrationProvider] Validation réussie, appel API...');
      
      // TODO: Remplacer par un vrai appel API d'inscription
      // Pour l'instant, simuler un appel API
      await Future.delayed(const Duration(seconds: 2));
      
      // Simuler une inscription réussie
      final success = await _simulateRegistration(data);
      
      if (success) {
        print('📝 [RegistrationProvider] ✅ Inscription réussie');
        
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          successMessage: 'Inscription réussie ! Vous pouvez maintenant vous connecter.',
        );

        // Optionnel: Se connecter automatiquement après l'inscription
        // await _ref.read(authStateProvider.notifier).login(data.email, data.password);
        
        return true;
      } else {
        throw Exception('Erreur lors de l\'inscription');
      }
    } catch (e) {
      print('📝 [RegistrationProvider] ❌ Erreur inscription: $e');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Simuler un appel API d'inscription
  Future<bool> _simulateRegistration(RegistrationData data) async {
    // Simuler différents cas de figure
    if (data.email == 'test@existe.com') {
      throw Exception('Cette adresse email est déjà utilisée');
    }
    
    if (data.email == 'erreur@test.com') {
      throw Exception('Erreur serveur lors de l\'inscription');
    }
    
    // Simuler une inscription réussie
    return true;
  }

  /// Valider le format email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Réinitialiser l'état
  void reset() {
    print('📝 [RegistrationProvider] Reset état');
    state = const RegistrationState();
  }

  /// Vérifier si un email est disponible
  Future<bool> checkEmailAvailability(String email) async {
    print('📝 [RegistrationProvider] Vérification disponibilité email: $email');
    
    try {
      // TODO: Remplacer par un vrai appel API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simuler une vérification
      if (email == 'test@existe.com') {
        return false; // Email déjà utilisé
      }
      
      return true; // Email disponible
    } catch (e) {
      print('📝 [RegistrationProvider] ❌ Erreur vérification email: $e');
      return false;
    }
  }

  /// Envoyer un code de vérification par email
  Future<bool> sendVerificationCode(String email) async {
    print('📝 [RegistrationProvider] Envoi code vérification: $email');
    
    try {
      // TODO: Remplacer par un vrai appel API
      await Future.delayed(const Duration(seconds: 1));
      
      print('📝 [RegistrationProvider] ✅ Code de vérification envoyé');
      return true;
    } catch (e) {
      print('📝 [RegistrationProvider] ❌ Erreur envoi code: $e');
      return false;
    }
  }

  /// Vérifier un code de vérification
  Future<bool> verifyCode(String email, String code) async {
    print('📝 [RegistrationProvider] Vérification code: $code pour $email');
    
    try {
      // TODO: Remplacer par un vrai appel API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simuler une vérification (code correct = "123456")
      if (code == "123456") {
        print('📝 [RegistrationProvider] ✅ Code vérifié');
        return true;
      } else {
        print('📝 [RegistrationProvider] ❌ Code incorrect');
        return false;
      }
    } catch (e) {
      print('📝 [RegistrationProvider] ❌ Erreur vérification code: $e');
      return false;
    }
  }
}

/// Provider principal pour l'inscription
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(AuthService(), ref);
});

/// Provider pour vérifier si l'inscription est en cours
final isRegisteringProvider = Provider<bool>((ref) {
  final registrationState = ref.watch(registrationProvider);
  return registrationState.isLoading;
});

/// Provider pour vérifier si l'inscription est réussie
final isRegistrationSuccessProvider = Provider<bool>((ref) {
  final registrationState = ref.watch(registrationProvider);
  return registrationState.isSuccess;
});
