// /lib/widgets/app_shell.dart

import 'package:flutter/material.dart';
import '../pages/config_page.dart';
import '../pages/ball_deck_page.dart';
import '../pages/train_page.dart';
import '../pages/plane_page.dart';
import '../pages/storage_page.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;

  const AppShell({super.key, required this.title, required this.child});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.grey[900]),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey),
              child: Text(
                'Ramp Loader',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              title: const Text(
                'Config',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _navigateTo(context, const ConfigPage()),
            ),
            ListTile(
              title: const Text(
                'Ball Deck',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _navigateTo(context, const BallDeckPage()),
            ),
            ListTile(
              title: const Text(
                'Trains',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _navigateTo(context, const TrainPage()),
            ),
            ListTile(
              title: const Text('Plane', style: TextStyle(color: Colors.white)),
              onTap: () => _navigateTo(context, const PlanePage()),
            ),
            ListTile(
              title: const Text(
                'Storage',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _navigateTo(context, const StoragePage()),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
