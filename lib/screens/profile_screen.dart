import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'simple_profile_screen.dart';

/// Wrapper pour ProfileScreen qui utilise SimpleProfileScreen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ce screen agit simplement comme un wrapper pour SimpleProfileScreen
    // Toute la logique est gérée dans SimpleProfileScreen
    return const SimpleProfileScreen();
  }
}

