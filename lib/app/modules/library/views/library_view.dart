import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/sync_service.dart';
import '../../../utils/datetime_extensions.dart';
import '../controllers/library_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../data/models/recording_model.dart';

class LibraryView extends GetView<LibraryController> {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 80.0,
            backgroundColor: Colors.teal,
            title: const Text('Sound Library', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            actions: [
              IconButton(
                onPressed: () {
                  Get.find<SyncService>().syncNow();
                  controller.loadRecordings();
                },
                icon: const Icon(Icons.sync, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => controller.searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.teal),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => FilterChip(
                    label: const Text('Mine', style: TextStyle(fontSize: 12)),
                    selected: controller.showOnlyMyRecordings.value,
                    onSelected: (_) => controller.toggleUserFilter(),
                    selectedColor: Colors.teal.withValues(alpha: 0.2),
                    checkmarkColor: Colors.teal,
                    visualDensity: VisualDensity.compact,
                  )),
                ],
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = controller.filteredRecordings;
            if (items.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No recordings found')),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recording = items[index];
                    return RecordingListItem(
                      key: ValueKey(recording.id),
                      recording: recording, 
                      controller: controller
                    );
                  },
                  childCount: items.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class RecordingListItem extends StatelessWidget {
  final Recording recording;
  final LibraryController controller;

  const RecordingListItem({super.key, required this.recording, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = recording.commonName;
    final isUnidentified = name == null || name.toLowerCase().contains('unidentified');
    
    // Trigger lazy load
    if (name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.resolveSpeciesInfo(name);
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(recording.id),
        direction: controller.canDeleteRecording(recording) ? DismissDirection.endToStart : DismissDirection.none,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => controller.deleteRecording(recording, context),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnidentified 
                ? Colors.purple.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[850]! : Colors.grey[200]!),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(Routes.DETAILS, arguments: recording),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Leading: Image/Icon
                    SpeciesImage(
                      name: name,
                      isUnidentified: isUnidentified,
                      controller: controller,
                    ),
                    const SizedBox(width: 12),
                    // Middle: Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Unidentified',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().add_jm().format(recording.timestamp.toIST()),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trailing: Confidence/Arrow
                    if (recording.confidence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${(recording.confidence! * 100).toInt()}%",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeciesImage extends StatelessWidget {
  final String? name;
  final bool isUnidentified;
  final LibraryController controller;

  const SpeciesImage({
    super.key, 
    required this.name, 
    required this.isUnidentified,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isUnidentified 
          ? Colors.purple.withValues(alpha: 0.1)
          : Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Obx(() {
          // Access the observable map to register dependency even if name is null
          final images = controller.speciesImages;
          final int _ = images.length;
          
          final String? imgUrl = name != null ? images[name] : null;
          
          if (imgUrl != null) {
            return CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              memCacheWidth: 100,
              placeholder: (_, __) => _buildPlaceholder(),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            );
          }
          return _buildPlaceholder();
        }),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(
      isUnidentified ? Icons.flutter_dash : Icons.music_note, 
      color: isUnidentified ? Colors.purple : Colors.teal, 
      size: 24
    );
  }
}
