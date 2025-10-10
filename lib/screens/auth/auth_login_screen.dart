import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/vegetal_form_widgets.dart';
import '../../widgets/menu/public_menu_view.dart';

/// Écran de connexion simplifié
class AuthLoginScreen extends ConsumerStatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  ConsumerState<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<AuthLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || !mounted) return;

    final role = authState.role?.toLowerCase();
    final savedFilters = ref.read(savedFiltersProvider);

    // Règles de redirection
    if (role == 'client') {
      // Cas spécial client : vers /restaurants
      // (Si tu veux absolument revenir aux menus quand savedFilters existe, dé-commente le bloc suivant)
      /*
    if (savedFilters != null) {
      ref.read(searchCriteriaProvider.notifier).state = savedFilters;
      ref.read(savedFiltersProvider.notifier).state = null;
      context.go('/menus');
      return;
    }
    */
      context.go('/restaurants');
      return;
    }

    // Tous les autres rôles (admin/restaurateur/fournisseur) -> profil
    context.go('/');
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Logo ou icône
              Center(
                child: VegetalIconContainer(
                  icon: Icons.login,
                ),
              ),
              const SizedBox(height: 24),
              
              // Titre
              Text(
                'Bienvenue sur Veg\'N Bio',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Connectez-vous à votre compte',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Email
              VegetalTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email',
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est requis';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mot de passe
              VegetalTextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                labelText: 'Mot de passe',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le mot de passe est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mot de passe oublié
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implémenter la récupération de mot de passe
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                      ),
                    );
                  },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton de connexion
              VegetalButton(
                text: 'Se connecter',
                onPressed: authState.isLoading ? null : _handleLogin,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 16),
              
              // Message d'erreur
              if (authState.hasError)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    authState.errorMessage ?? 'Une erreur est survenue',
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              
              // Lien vers l'inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}