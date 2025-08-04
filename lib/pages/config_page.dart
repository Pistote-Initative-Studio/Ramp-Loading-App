import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/config_provider.dart';

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    if (config == null) {
      debugPrint('ConfigPage early exit: config is null');
      return Scaffold(
        appBar: AppBar(title: const Text('Config')),
        body: const Center(child: Text('No configuration loaded')),
      );
    }

    debugPrint('ConfigPage build with config for ${config.aircraft.typeCode}');
    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aircraft: ${config.aircraft.typeCode}'),
              const SizedBox(height: 8),
              Text('Allowed ULDs: ${config.allowedUlds.length}'),
              const SizedBox(height: 8),
              Text('Trains: ${config.trains.length}'),
            ],
          ),
        ),
      ),
    );
  }
}
