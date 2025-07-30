import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Restaurants'),
      ),
      body: const Center(
        child: Text('Page des restaurants à venir'),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}