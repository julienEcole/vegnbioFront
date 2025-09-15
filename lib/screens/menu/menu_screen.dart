import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/menu/public_menu_view.dart';
import '../../utils/web_logger.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  MenuScreen({super.key, this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[MenuScreen] BUILD APPELÉ !', '🍽️', color: '#4CAF50');
    return PublicMenuView(restaurantId: widget.restaurantId);
  }
}