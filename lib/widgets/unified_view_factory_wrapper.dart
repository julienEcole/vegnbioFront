import 'package:flutter/material.dart';
import '../factories/simple_view_factory.dart';
import '../utils/web_logger.dart';

/// Wrapper unifié qui remplace tous les anciens wrappers concurrents
/// 
/// Ce wrapper délègue TOUT à UnifiedViewFactory qui gère l'authentification
/// de manière cohérente sans concurrence entre les différents systèmes
class UnifiedViewFactoryWrapper extends StatelessWidget {
  final String pageType;
  final Map<String, dynamic>? parameters;
  final Widget? fallbackView;
  final bool requireAuth;

  const UnifiedViewFactoryWrapper({
    super.key,
    required this.pageType,
    this.parameters,
    this.fallbackView,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[UnifiedViewFactoryWrapper] BUILD APPELÉ !', '🚨', color: '#FF9800');
    WebLogger.logStyled('===== DÉBUT build() =====', color: '#FF9800');
    WebLogger.logStyled('PageType: $pageType', color: '#FF9800');
    WebLogger.logStyled('RequireAuth: $requireAuth', color: '#FF9800');
    
    return SimpleViewFactory.createView(
      pageType: pageType,
      parameters: parameters,
      fallbackView: fallbackView,
      requireAuth: requireAuth,
    );
  }
}

/// Extension pour faciliter l'utilisation
extension UnifiedViewFactoryExtension on Widget {
  /// Protège un écran avec le système unifié
  Widget unifiedAuth({
    required String pageType,
    Map<String, dynamic>? parameters,
    Widget? fallbackView,
    bool requireAuth = true,
  }) {
    return UnifiedViewFactoryWrapper(
      pageType: pageType,
      parameters: parameters,
      fallbackView: fallbackView,
      requireAuth: requireAuth,
    );
  }
}
