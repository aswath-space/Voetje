import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/widgets/add_place_sheet.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmissionProvider>();
    final places = provider.savedPlaces;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: places.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No places saved yet'),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to add a place',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: places.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, i) => _PlaceTile(place: places[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddPlaceSheet(),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final SavedPlace place;
  const _PlaceTile({required this.place});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place_outlined),
      title: Text(place.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context),
      ),
      onTap: () => _showEditSheet(context),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPlaceSheet(editing: place),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<EmissionProvider>();
    final count = await provider.routePresetCountForPlace(place.id!);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text(count > 0
            ? 'This will also remove $count saved route${count == 1 ? '' : 's'}.'
            : 'This place will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deletePlace(place.id!);
    }
  }
}
