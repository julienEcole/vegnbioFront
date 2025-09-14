import 'package:flutter/material.dart';
import '../widgets/unified_view_factory_wrapper.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedViewFactoryWrapper(
      pageType: 'services',
      requireAuth: false, // Les services sont publics par défaut
    );
  }

}