import 'package:flutter/material.dart';
import '../widgets/unified_view_factory_wrapper.dart';
import '../utils/web_logger.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[HomeScreen] BUILD APPELÉ !', '🚨', color: '#4CAF50');
    
    return const UnifiedViewFactoryWrapper(
      pageType: 'home',
      requireAuth: false, // La page d'accueil est publique
    );
  }
}