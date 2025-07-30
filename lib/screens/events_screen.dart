import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
      ),
      body: const Center(
        child: Text('Page des événements à venir'),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}