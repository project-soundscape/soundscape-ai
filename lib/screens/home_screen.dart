import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/soundscape_provider.dart';
import '../widgets/soundscape_player.dart';
import '../widgets/sound_category_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Soundscape'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Consumer<SoundscapeProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Currently playing section
              const SoundscapePlayer(),
              
              // Divider
              const Divider(),
              
              // Sound categories section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Soundscapes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Expanded(
                        child: SoundCategoryGrid(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Toggle play/pause for current soundscape
          context.read<SoundscapeProvider>().togglePlayPause();
        },
        child: Consumer<SoundscapeProvider>(
          builder: (context, provider, child) {
            return Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
            );
          },
        ),
      ),
    );
  }
}