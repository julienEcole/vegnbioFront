import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/unified_view_factory_wrapper.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  final int? highlightRestaurantId;
  
  const RestaurantsScreen({super.key, this.highlightRestaurantId});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  @override
  Widget build(BuildContext context) {
    return UnifiedViewFactoryWrapper(
      pageType: 'restaurants',
      parameters: {
        'highlightRestaurantId': widget.highlightRestaurantId,
      },
      requireAuth: false, // Les restaurants sont publics par défaut
    );
  }
}