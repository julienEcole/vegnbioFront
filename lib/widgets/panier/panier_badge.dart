import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/panier_provider.dart';

class PanierBadge extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PanierBadge({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombreArticles = ref.watch(panierStatsProvider)['nombreArticles'] as int;

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: child,
        ),
        if (nombreArticles > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                nombreArticles > 99 ? '99+' : nombreArticles.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class PanierFloatingActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const PanierFloatingActionButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombreArticles = ref.watch(panierStatsProvider)['nombreArticles'] as int;

    return Stack(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.green,
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.white,
          ),
        ),
        if (nombreArticles > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                nombreArticles > 99 ? '99+' : nombreArticles.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
