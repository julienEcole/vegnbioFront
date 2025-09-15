import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigation_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _getSelectedIndex() {
    switch (widget.currentRoute) {
      case '/':
        return 0;
      case '/menus':
        return 1;
      case '/restaurants':
        return 2;
      case '/evenements':
        return 3;
      case '/profil':
        return 4;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/menus');
        break;
      case 2:
        context.go('/restaurants');
        break;
      case 3:
        context.go('/evenements');
        break;
      case 4:
        context.go('/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _getSelectedIndex(),
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
