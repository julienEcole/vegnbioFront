import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Menus'),
      ),
      body: const Center(
        child: Text('Page des menus à venir'),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}