import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/soundscape_provider.dart';
import '../models/soundscape.dart';

class SoundCategoryGrid extends StatelessWidget {
  const SoundCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SoundscapeProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final soundscapes = provider.getSoundscapesByCategory(category);
            
            return _CategoryCard(
              category: category,
              soundscapes: soundscapes,
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final List<Soundscape> soundscapes;

  const _CategoryCard({
    required this.category,
    required this.soundscapes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showCategorySoundscapes(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${soundscapes.length} soundscape${soundscapes.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategorySoundscapes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SoundscapeListBottomSheet(
        category: category,
        soundscapes: soundscapes,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return Icons.forest;
      case 'water':
        return Icons.waves;
      case 'urban':
        return Icons.location_city;
      default:
        return Icons.music_note;
    }
  }
}

class _SoundscapeListBottomSheet extends StatelessWidget {
  final String category;
  final List<Soundscape> soundscapes;

  const _SoundscapeListBottomSheet({
    required this.category,
    required this.soundscapes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: soundscapes.length,
              itemBuilder: (context, index) {
                final soundscape = soundscapes[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(soundscape.category),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(soundscape.name),
                  subtitle: Text(soundscape.description),
                  trailing: Text(
                    '${soundscape.duration.inMinutes}:${(soundscape.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    context.read<SoundscapeProvider>().playSoundscape(soundscape);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return Icons.forest;
      case 'water':
        return Icons.waves;
      case 'urban':
        return Icons.location_city;
      default:
        return Icons.music_note;
    }
  }
}