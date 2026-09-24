import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            selectedIcon: Icon(Icons.business_center),
            label: 'Career',
          ),
          NavigationDestination(
            icon: Icon(Icons.laptop_chromebook_outlined),
            selectedIcon: Icon(Icons.laptop_chromebook),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

