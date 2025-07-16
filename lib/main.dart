import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/container.dart' as model;
import 'models/train.dart';
import 'models/tug.dart';
import 'models/plane.dart';
import 'pages/train_page.dart';
import 'pages/ball_deck_page.dart';
import 'pages/plane_page.dart';
import 'pages/config_page.dart';
import 'pages/storage_page.dart';
import 'widgets/transfer_area.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(model.StorageContainerAdapter());
  Hive.registerAdapter(DollyAdapter());
  Hive.registerAdapter(TrainAdapter());
  Hive.registerAdapter(TugAdapter());
  Hive.registerAdapter(PlaneAdapter());

  // Open Hive boxes
  await Hive.openBox('ballDeckBox');
  await Hive.openBox('trainBox');
  await Hive.openBox('tugBox');
  await Hive.openBox('planeBox');

  runApp(const ProviderScope(child: RampLoaderApp()));
}

class RampLoaderApp extends StatelessWidget {
  const RampLoaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.black,
        canvasColor: Colors.black,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        dividerColor: Colors.white24,
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: const HomeNav(),
    );
  }
}

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  final PageController _controller = PageController();
  int page = 0;

  void jumpToPage(int index) {
    setState(() {
      page = index;
    });
    _controller.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ConfigPage(), // index 0
          BallDeckPage(), // index 1
          TrainPage(), // index 2
          PlanePage(), // index 3
          StoragePage(), // index 4
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (page != 0 && page != 2) const TransferArea(),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white, width: 1)),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.black,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: page,
              onTap: jumpToPage,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Config',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Deck'),
                BottomNavigationBarItem(icon: Icon(Icons.train), label: 'Trains'),
                BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Plane'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.warehouse),
                  label: 'Storage',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
