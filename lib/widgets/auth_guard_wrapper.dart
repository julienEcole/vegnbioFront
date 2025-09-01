import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_guard_service.dart';
import '../factories/view_factory.dart';

/// Widget qui protège un écran en vérifiant l'authentification et les rôles
/// Affiche une version publique si le token est invalide et qu'une vue publique existe
/// Sinon redirige vers la page de connexion
class AuthGuardWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? publicView;
  final String pageType; // 'admin', 'restaurateur', 'fournisseur', 'client', 'public'
  final bool requireAuth;
  final String? customMessage;
  final VoidCallback? onAccessDenied;
  final VoidCallback? onTokenInvalid;

  const AuthGuardWrapper({
    super.key,
    required this.child,
    this.publicView,
    required this.pageType,
    this.requireAuth = true,
    this.customMessage,
    this.onAccessDenied,
    this.onTokenInvalid,
  });

  @override
  ConsumerState<AuthGuardWrapper> createState() => _AuthGuardWrapperState();
}

class _AuthGuardWrapperState extends ConsumerState<AuthGuardWrapper> {
  bool _isCheckingAuth = true;
  bool _hasAccess = false;
  bool _isValidToken = false;
  String? _userRole;
  String _statusMessage = 'Vérification de l\'authentification...';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      print('🔐 AuthGuardWrapper: Vérification de l\'authentification pour ${widget.pageType}...');
      
      final authGuard = AuthGuardService();
      final result = await authGuard.checkAccess(
        pageType: widget.pageType,
        requireAuth: widget.requireAuth,
      );

      print('🔐 AuthGuardWrapper: Résultat: $result');

      setState(() {
        _hasAccess = result.hasAccess;
        _isValidToken = result.isValidToken;
        _userRole = result.userRole;
        _statusMessage = result.message;
        _isCheckingAuth = false;
      });

      // Gérer les cas d'erreur
      if (!result.isValidToken) {
        print('🚨 AuthGuardWrapper: Token invalide détecté');
        _handleTokenInvalid();
      } else if (!result.hasAccess) {
        print('🚫 AuthGuardWrapper: Accès refusé pour le rôle: ${result.userRole}');
        _handleAccessDenied();
      } else {
        print('✅ AuthGuardWrapper: Accès autorisé pour ${result.userRole}');
      }
    } catch (e) {
      print('❌ AuthGuardWrapper: Erreur lors de la vérification: $e');
      setState(() {
        _hasAccess = false;
        _isValidToken = false;
        _isCheckingAuth = false;
        _statusMessage = 'Erreur lors de la vérification: $e';
      });
      _handleTokenInvalid();
    }
  }

  void _handleTokenInvalid() {
    // Appeler le callback personnalisé si fourni
    if (widget.onTokenInvalid != null) {
      widget.onTokenInvalid!();
    }

    // Afficher le popup temporaire
    if (mounted) {
      final authGuard = AuthGuardService();
      authGuard.showTokenInvalidPopup(
        context,
        customMessage: widget.customMessage ?? 'Token invalide. Redirection vers la page de connexion...',
      );

      // Si une vue publique existe, l'afficher après le popup
      if (widget.publicView != null) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _hasAccess = true; // Permettre l'affichage de la vue publique
            });
          }
        });
      } else {
        // Sinon rediriger vers la page de connexion
        authGuard.redirectToLogin(context);
      }
    }
  }

  void _handleAccessDenied() {
    // Appeler le callback personnalisé si fourni
    if (widget.onAccessDenied != null) {
      widget.onAccessDenied!();
    }

    // Afficher un message d'accès refusé
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.customMessage ?? 'Accès refusé. Rôle insuffisant pour cette page.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Rediriger vers la page de connexion après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.push('/profil');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si on vérifie encore l'authentification, afficher un indicateur de chargement
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vérification du rôle: ${widget.pageType}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Si l'utilisateur a accès, afficher l'écran protégé
    if (_hasAccess && _isValidToken) {
      return widget.child;
    }

    // Si le token est invalide mais qu'une vue publique existe, l'afficher
    if (!_isValidToken && widget.publicView != null) {
      print('📱 AuthGuardWrapper: Affichage de la vue publique pour ${widget.pageType}');
      return widget.publicView!;
    }

    // Si pas de vue publique et accès refusé, afficher un message d'attente
    // (la redirection se fera automatiquement)
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isValidToken ? Icons.block : Icons.lock_outline,
              size: 64,
              color: _isValidToken ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _isValidToken ? 'Accès refusé' : 'Session expirée',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_userRole != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rôle actuel: $_userRole',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Redirection en cours...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension pour faciliter l'utilisation avec les écrans
extension AuthGuardExtension on Widget {
  /// Protège un écran en vérifiant l'authentification et les rôles
  Widget authGuard({
    required String pageType,
    Widget? publicView,
    bool requireAuth = true,
    String? customMessage,
    VoidCallback? onAccessDenied,
    VoidCallback? onTokenInvalid,
  }) {
    return AuthGuardWrapper(
      child: this,
      pageType: pageType,
      publicView: publicView,
      requireAuth: requireAuth,
      customMessage: customMessage,
      onAccessDenied: onAccessDenied,
      onTokenInvalid: onTokenInvalid,
    );
  }
}
