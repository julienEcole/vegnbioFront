import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'navigation/responsive_navigation.dart';

/// Layout principal de l'application avec navigation responsive + init auth
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // ✅ Initialiser l'authentification après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        ref.read(authProvider.notifier).checkAuthStatus();
        _isInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= kDesktopBreakpoint;

    if (isDesktop) {
      // ✅ Layout Desktop : sidebar à gauche
      return Scaffold(
        body: Row(
          children: [
            // Sidebar de navigation responsive
            NavigationSidebar(currentRoute: widget.currentRoute),

            // Contenu principal
            Expanded(child: widget.child),
          ],
        ),
      );
    } else {
      // ✅ Layout Mobile : bottom navigation responsive
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: ResponsiveNavigationBar(
          currentRoute: widget.currentRoute,
        ),
      );
    }
  }
}
