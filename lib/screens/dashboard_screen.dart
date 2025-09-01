import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../factories/dashboard_factory.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardWidget = ref.watch(dashboardScreenProvider);
    
    return Scaffold(
      body: dashboardWidget,
    );
  }
}
