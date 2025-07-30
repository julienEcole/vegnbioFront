import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: const Center(
        child: Text('Page de profil à venir'),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}