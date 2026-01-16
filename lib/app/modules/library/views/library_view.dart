import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/library_controller.dart';
import '../../../routes/app_pages.dart';

class LibraryView extends GetView<LibraryController> {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is loaded if not already (though Binding handles it)
    if(!Get.isRegistered<LibraryController>()) {
      Get.put(LibraryController());
    } else {
      controller.refreshList(); // refresh when rebuilt
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.recordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.library_music_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No recordings yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshList(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.recordings.length,
            itemBuilder: (context, index) {
              final recording = controller.recordings[index];
              return Dismissible(
                key: Key(recording.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Recording?'),
                      content: const Text('This will delete the file from your device and the cloud.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => controller.deleteRecording(recording),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      child: const Icon(Icons.music_note, color: Colors.teal),
                    ),
                    title: Text(
                      recording.commonName ?? 'Unidentified Sound',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(DateFormat.yMMMd().add_jm().format(recording.timestamp)),
                        if(recording.status == 'pending')
                          const Text('Pending Analysis', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Get.toNamed(Routes.DETAILS, arguments: recording);
                    },
                    onLongPress: () {
                      final textController = TextEditingController(text: recording.commonName);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Rename Recording'),
                          content: TextField(
                            controller: textController,
                            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog first
                                controller.editRecording(recording, textController.text);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
        ));
      }),
    );
  }
}