import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../factories/view_factory.dart';
import '../providers/auth_provider.dart';

/// Wrapper qui utilise ViewFactory avec AuthProvider pour déterminer la vue appropriée
class ViewFactoryWrapper extends ConsumerWidget {
  final String pageType;
  final Map<String, dynamic>? parameters;
  final Widget? fallbackView;

  const ViewFactoryWrapper({
    super.key,
    required this.pageType,
    this.parameters,
    this.fallbackView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Déterminer l'état d'authentification
    bool isAuthenticated = false;
    String? userRole;

    if (authState is AuthenticatedAuthState) {
      isAuthenticated = true;
      userRole = authState.role;
    } else if (authState is LoadingAuthState || authState is InitialAuthState) {
      // Pendant le chargement, afficher la vue de chargement
      return _buildLoadingView();
    }

    // Utiliser ViewFactory pour déterminer la vue appropriée
    return ViewFactory.createView(
      pageType: pageType,
      isAuthenticated: isAuthenticated,
      userRole: userRole,
      parameters: parameters,
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chargement...'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de la page...'),
          ],
        ),
      ),
    );
  }
}
