import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoundScape'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal[800],
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Timer
                Obx(
                  () => Text(
                    '${controller.globalDuration.value.inMinutes.toString().padLeft(2, '0')} : ${(controller.globalDuration.value.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: Colors.black87,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Main Action Button
                Obx(() {
                  if (controller.isCompletedRecording.value) {
                    // Review State
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             IconButton(
                               iconSize: 48,
                               icon: Icon(controller.isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled),
                               color: Colors.teal,
                               onPressed: () {
                                 if (controller.isPlaying.value) {
                                   controller.pausePlaying();
                                 } else if (controller.isPaused.value) {
                                   controller.resumePlaying();
                                 } else {
                                   controller.startPlaying();
                                 }
                               },
                             ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              onPressed: controller.discardRecording,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Discard'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: controller.saveRecording,
                              icon: const Icon(Icons.check),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Recording State
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: controller.toggleRecording,
                          child: Obx(() {
                            final bool isUnderMin = controller.isRecording.value && controller.globalDuration.value.inSeconds < 15;
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: controller.isRecording.value 
                                  ? (isUnderMin ? Colors.grey[400] : Colors.redAccent) 
                                  : Colors.teal,
                                boxShadow: [
                                  BoxShadow(
                                    color: (controller.isRecording.value 
                                      ? (isUnderMin ? Colors.grey : Colors.redAccent) 
                                      : Colors.teal).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: Icon(
                                controller.isRecording.value ? Icons.stop : Icons.mic,
                                size: 56,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),
                        if (controller.isRecording.value) ...[
                          const SizedBox(height: 32),
                          TextButton.icon(
                            onPressed: controller.discardRecording,
                            icon: const Icon(Icons.close, color: Colors.grey),
                            label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ]
                      ],
                    );
                  }
                }),
                
                const Spacer(),
                Obx(() => controller.isRecording.value 
                  ? const Text("Recording... Keep device steady.", style: TextStyle(color: Colors.grey))
                  : const SizedBox.shrink()
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}