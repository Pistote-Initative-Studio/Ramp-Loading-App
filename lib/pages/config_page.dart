import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/config_provider.dart';

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  /// Ensure that the Hive boxes used throughout the configuration
  /// section are opened before we try to read from them. This mirrors
  /// the behaviour on other pages where the plane or train boxes are
  /// required for state.
  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen('configBox')) {
      await Hive.openBox('configBox');
    }
    if (!Hive.isBoxOpen('planeBox')) {
      await Hive.openBox('planeBox');
    }
    if (!Hive.isBoxOpen('trainBox')) {
      await Hive.openBox('trainBox');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _ensureBoxesOpen(),
      builder: (context, snapshot) {
        final config = ref.watch(configProvider);

        // Even if [config] is still null or empty we continue to build the
        // full UI so that the user can populate it. This avoids returning
        // early with placeholders that hide the real widgets.
        final aircraftCode = config?.aircraft.typeCode ?? 'UNKNOWN';
        final uldCount = config?.allowedUlds.length ?? 0;
        final trainCount = config?.trains.length ?? 0;

        debugPrint('ConfigPage build with aircraft: $aircraftCode');

        return Scaffold(
          appBar: AppBar(title: const Text('Config')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aircraft: $aircraftCode'),
                  const SizedBox(height: 8),
                  Text('Allowed ULDs: $uldCount'),
                  const SizedBox(height: 8),
                  Text('Trains: $trainCount'),
                  const SizedBox(height: 16),
                  _buildAircraftSection(config),
                  const SizedBox(height: 16),
                  _buildAllowedUldsSection(config),
                  const SizedBox(height: 16),
                  _buildTrainsSection(config),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays details about the currently selected aircraft or a
  /// placeholder if no aircraft has been configured yet.
  Widget _buildAircraftSection(LoadConfig? config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aircraft Configuration'),
        if (config != null)
          Text('Type: ${config.aircraft.typeCode}')
        else
          const Text('No aircraft selected'),
      ],
    );
  }

  /// Displays the allowed ULD types. When the list is empty we still
  /// render the heading with a message so that the section is visible
  /// to the user.
  Widget _buildAllowedUldsSection(LoadConfig? config) {
    final ulds = config?.allowedUlds ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Allowed ULD Types'),
        if (ulds.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [for (final u in ulds) Chip(label: Text(u.code))],
          )
        else
          const Text('No ULD types configured'),
      ],
    );
  }

  /// Displays the configured trains. This section is visible even
  /// when there are no trains so the user knows where to add them.
  Widget _buildTrainsSection(LoadConfig? config) {
    final trains = config?.trains ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Train Configuration'),
        if (trains.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in trains)
                Text('${t.label} (${t.dollys.length} dollys)'),
            ],
          )
        else
          const Text('No trains configured'),
      ],
    );
  }
}
