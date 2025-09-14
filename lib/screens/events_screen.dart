import 'package:flutter/material.dart';
import '../widgets/unified_view_factory_wrapper.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedViewFactoryWrapper(
      pageType: 'events',
      requireAuth: false, // Les événements sont publics par défaut
    );
  }

}