import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/restaurant/public_restaurant_view.dart';
import '../../utils/web_logger.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  final int? highlightRestaurantId;
  
  const RestaurantsScreen({super.key, this.highlightRestaurantId});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[RestaurantsScreen] BUILD APPELÉ !', '🏪', color: '#FF5722');
    return PublicRestaurantView(highlightRestaurantId: widget.highlightRestaurantId);
  }
}