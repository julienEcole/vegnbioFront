import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/restaurateur_dashboard_screen.dart';
import '../screens/fournisseur_dashboard_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../providers/navigation_provider.dart';

enum UserRole {
  client,
  restaurateur,
  fournisseur,
  admin,
}

class DashboardFactory {
  static Widget createDashboard(UserRole role) {
    switch (role) {
      case UserRole.restaurateur:
        return const RestaurateurDashboardScreen();
      case UserRole.fournisseur:
        return const FournisseurDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.client:
      default:
        return _buildClientDashboard();
    }
  }

  static Widget _buildClientDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Client'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Bienvenue dans votre espace client',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Consultez les restaurants et menus disponibles',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static UserRole parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'restaurateur':
        return UserRole.restaurateur;
      case 'fournisseur':
        return UserRole.fournisseur;
      case 'admin':
        return UserRole.admin;
      case 'client':
      default:
        return UserRole.client;
    }
  }
}

// Provider pour l'écran de tableau de bord
final dashboardScreenProvider = Provider<Widget>((ref) {
  final userRoleAsync = ref.watch(userRoleProvider);
  
  return userRoleAsync.when(
    data: (role) => DashboardFactory.createDashboard(role),
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Scaffold(
      body: Center(
        child: Text('Erreur: $error'),
      ),
    ),
  );
});
