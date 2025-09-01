import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/token_validator_service.dart';

/// Widget qui protège un écran en vérifiant la validité du token
/// Si le token est invalide et qu'aucune vue publique n'est fournie, 
/// l'utilisateur est redirigé vers le profil
class ProtectedScreenWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? publicView;
  final bool requireAuth;
  final String? redirectMessage;
  final VoidCallback? onTokenInvalid;

  const ProtectedScreenWrapper({
    super.key,
    required this.child,
    this.publicView,
    this.requireAuth = true,
    this.redirectMessage,
    this.onTokenInvalid,
  });

  @override
  ConsumerState<ProtectedScreenWrapper> createState() => _ProtectedScreenWrapperState();
}

class _ProtectedScreenWrapperState extends ConsumerState<ProtectedScreenWrapper> {
  bool _isCheckingToken = true;
  bool _isTokenValid = false;
  bool _hasCheckedOnce = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    if (!widget.requireAuth) {
      setState(() {
        _isCheckingToken = false;
        _isTokenValid = true;
      });
      return;
    }

    try {
      print('🔐 ProtectedScreenWrapper: Vérification du token...');
      final tokenValidator = TokenValidatorService();
      final isValid = await tokenValidator.ensureTokenValid();
      
      print('🔐 ProtectedScreenWrapper: Token valide: $isValid');
      
      setState(() {
        _isTokenValid = isValid;
        _isCheckingToken = false;
        _hasCheckedOnce = true;
      });

      if (!isValid) {
        print('🚨 ProtectedScreenWrapper: Token invalide, redirection vers le profil...');
        _handleTokenInvalid();
      }
    } catch (e) {
      print('❌ ProtectedScreenWrapper: Erreur lors de la vérification du token: $e');
      setState(() {
        _isTokenValid = false;
        _isCheckingToken = false;
        _hasCheckedOnce = true;
      });
      _handleTokenInvalid();
    }
  }

  void _handleTokenInvalid() {
    // Appeler le callback personnalisé si fourni
    if (widget.onTokenInvalid != null) {
      widget.onTokenInvalid!();
    }

    // Afficher un message et rediriger
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.redirectMessage ?? 'Session expirée. Redirection vers le profil...'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      // Rediriger vers le profil après un court délai
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          print('🔄 ProtectedScreenWrapper: Redirection vers /profil...');
          context.push('/profil');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si on vérifie encore le token, afficher un indicateur de chargement
    if (_isCheckingToken) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification de l\'authentification...'),
            ],
          ),
        ),
      );
    }

    // Si le token est valide, afficher l'écran protégé
    if (_isTokenValid) {
      return widget.child;
    }

    // Si le token est invalide mais qu'une vue publique est fournie, l'afficher
    if (widget.publicView != null) {
      print('📱 ProtectedScreenWrapper: Affichage de la vue publique');
      return widget.publicView!;
    }

    // Si pas de vue publique et token invalide, afficher un message d'attente
    // (la redirection se fera automatiquement)
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              widget.redirectMessage ?? 'Session expirée',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Redirection vers le profil...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Extension pour faciliter l'utilisation avec les écrans
extension ProtectedScreenExtension on Widget {
  /// Protège un écran en vérifiant l'authentification
  Widget protected({
    Widget? publicView,
    bool requireAuth = true,
    String? redirectMessage,
    VoidCallback? onTokenInvalid,
  }) {
    return ProtectedScreenWrapper(
      child: this,
      publicView: publicView,
      requireAuth: requireAuth,
      redirectMessage: redirectMessage,
      onTokenInvalid: onTokenInvalid,
    );
  }
}
