import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/soundscape_provider.dart';

class SoundscapePlayer extends StatelessWidget {
  const SoundscapePlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SoundscapeProvider>(
      builder: (context, provider, child) {
        final currentSoundscape = provider.currentSoundscape;
        
        if (currentSoundscape == null) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Select a soundscape to start',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Current soundscape info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            _getCategoryIcon(currentSoundscape.category),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSoundscape.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              currentSoundscape.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.stop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Volume control
                  Row(
                    children: [
                      Icon(
                        Icons.volume_down,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.volume,
                          onChanged: (value) => provider.setVolume(value),
                          min: 0.0,
                          max: 1.0,
                        ),
                      ),
                      Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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