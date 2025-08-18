import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/container.dart' as model;
import 'models/size_enum_adapter.dart';
import 'models/train.dart';
import 'models/tug.dart';
import 'models/plane.dart';
import 'providers/ball_deck_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads/ads_controller.dart';
import 'shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(model.kStorageContainerTypeId)) {
    Hive.registerAdapter(model.StorageContainerAdapter());
  }
  Hive.registerAdapter(TrainAdapter());
  Hive.registerAdapter(DollyAdapter());
  Hive.registerAdapter(TugAdapter());
  Hive.registerAdapter(PlaneAdapter());
  Hive.registerAdapter(SizeEnumAdapter());
  Hive.registerAdapter(BallDeckStateAdapter());

  // Ensure required Hive boxes are open before the app starts.
  await Future.wait([
    Hive.openBox('ballDeckBox'),
    Hive.openBox('transferBox'),
    Hive.openBox('uldPlacementBox'),
    Hive.openBox('configBox'),
    Hive.openBox('planeBox'),
    Hive.openBox('planesBox'),
    Hive.openBox('trainBox'),
    Hive.openBox('tugBox'),
    Hive.openBox('tugsBox'),
    Hive.openBox('uldBox'),
    Hive.openBox('storage_config'),
    Hive.openBox('storage_items'),
  ]);

  await MobileAds.instance.initialize();
  await AdsController.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const AppShell(),
    );
  }
}
