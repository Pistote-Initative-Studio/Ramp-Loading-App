import 'package:flutter/material.dart';

import '../ads/ads_controller.dart';
import '../pages/config_page.dart';
import '../pages/ball_deck_page.dart';
import '../pages/train_page.dart';
import '../pages/plane_page.dart';
import '../pages/storage_page.dart';
import '../widgets/transfer_bin.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _controller = PageController();
  int _page = 0;

  final _tabs = const [
    ConfigPage(),
    BallDeckPage(),
    TrainPage(),
    PlanePage(),
    StoragePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Show an interstitial shortly after launch
    Future.delayed(const Duration(milliseconds: 1500), () {
      AdsController.instance.maybeShowInterstitial(trigger: 'sessionStart');
    });
  }

  void _jumpToPage(int index) {
    setState(() => _page = index);
    _controller.jumpToPage(index);
    AdsController.instance.maybeShowInterstitial(trigger: 'tab');
  }

  @override
  Widget build(BuildContext context) {
    final ads = AdsController.instance;
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _tabs,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ads.bannerVisible)
              SizedBox(
                height: kBannerHeight,
                width: double.infinity,
                child: ads.bannerWidget!,
              ),
            const TransferBin(),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white, width: 1)),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.black,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                currentIndex: _page,
                onTap: _jumpToPage,
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
      ),
    );
  }
}
