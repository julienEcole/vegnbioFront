import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Services'),
      ),
      body: const Center(
        child: Text('Page des services à venir'),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}