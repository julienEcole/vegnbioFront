import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'events/events_screen.dart';
import 'service/services_screen.dart';
import 'restaurant/restaurants_screen.dart';
import '../widgets/navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        // print('🏠 [MainScreen] HomeScreen');
        return const HomeScreen();
      case 1:
        return MenuScreen();
      case 2:
        return const EventsScreen();
      case 3:
        return const ServicesScreen();
      case 4:
        return const RestaurantsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('🧭 [MainScreen] BUILD APPELÉ ! Index: $_selectedIndex');
    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          // print('🔄 [MainScreen] Navigation vers index: $index');
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
