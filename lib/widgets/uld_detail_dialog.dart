import 'package:flutter/material.dart';
import '../models/container.dart' as model;

class UldDetailDialog extends StatelessWidget {
  final model.StorageContainer container;
  final VoidCallback onUpdate;

  const UldDetailDialog({
    super.key,
    required this.container,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(container.uld, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Type: ${container.type}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('DG', style: TextStyle(color: Colors.white)),
              Checkbox(
                value: container.dangerousGoods,
                activeColor: Colors.amber,
                checkColor: Colors.black,
                onChanged: (checked) async {
                  if (checked == true) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to mark this ULD as Dangerous Goods?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                    );
                    if (confirm != true) return;
                  }
                  container.dangerousGoods = checked ?? false;
                  onUpdate();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
