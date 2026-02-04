import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/sync_service.dart';
import '../controllers/library_controller.dart';
import '../../../routes/app_pages.dart';

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
            expandedHeight: 120.0,
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                onPressed: () {
                  Get.find<SyncService>().syncNow();
                  controller.loadRecordings();
                },
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync now',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Sound Library', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              centerTitle: false,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search recordings...',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          // Filter button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Obx(() => FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: controller.showOnlyMyRecordings.value ? Colors.white : Colors.teal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My Recordings',
                          style: TextStyle(
                            color: controller.showOnlyMyRecordings.value ? Colors.white : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    selected: controller.showOnlyMyRecordings.value,
                    onSelected: (_) => controller.toggleUserFilter(),
                    selectedColor: Colors.teal,
                    checkmarkColor: Colors.white,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: controller.showOnlyMyRecordings.value ? Colors.teal : Colors.grey.shade300,
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Obx(() => Text(
                    '${controller.filteredRecordings.length} recording(s)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  )),
                ],
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.teal)),
              );
            }

            if (controller.filteredRecordings.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.graphic_eq, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.isNotEmpty
                            ? 'No matching sounds found'
                            : 'No recordings yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recording = controller.filteredRecordings[index];
                    final isUnidentified = (recording.commonName ?? '').toLowerCase().contains('unidentified');
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(recording.id),
                        direction: controller.canDeleteRecording(recording) 
                            ? DismissDirection.endToStart 
                            : DismissDirection.none,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (direction) async {
                          if (!controller.canDeleteRecording(recording)) {
                            Get.snackbar(
                              'Permission Denied',
                              'You can only delete your own recordings',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return false;
                          }
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Recording?'),
                              content: const Text('This will permanently delete the file.'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => controller.deleteRecording(recording),
                        child: Hero(
                          tag: 'recording_${recording.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Get.toNamed(Routes.DETAILS, arguments: recording),
                              onLongPress: (recording.commonName == null || 
                                            recording.commonName!.toLowerCase().contains('unidentified')) 
                                  ? () => _showRenameDialog(context, recording) 
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? (isUnidentified ? Colors.purple.withValues(alpha: 0.15) : Colors.grey[900])
                                      : (isUnidentified ? Colors.purple.withValues(alpha: 0.05) : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: isUnidentified ? Border.all(color: Colors.purple.withValues(alpha: 0.3)) : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Stack(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.music_note_rounded, color: Colors.teal, size: 28),
                                      ),
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[900] : Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            recording.isLocal ? Icons.offline_pin_rounded : Icons.cloud_outlined,
                                            size: 14,
                                            color: recording.isLocal ? Colors.teal : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              recording.commonName ?? 'Unidentified Sound',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 16, 
                                                color: Theme.of(context).textTheme.bodyLarge?.color
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (recording.userId != null && recording.userId == controller.currentUserId)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                              ),
                                              child: const Text(
                                                'Mine',
                                                style: TextStyle(
                                                  color: Colors.teal,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (recording.predictions != null && 
                                          recording.predictions!.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '+${recording.predictions!.length - 1} more species',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat.yMMMd().add_jm().format(recording.timestamp),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      if (recording.status == 'pending')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                                height: 10,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Analyzing...', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (recording.confidence != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            "${recording.confidence!.toInt()}%",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: controller.filteredRecordings.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, dynamic recording) {
    final textController = TextEditingController(text: recording.commonName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Recording'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.editRecording(recording, textController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}