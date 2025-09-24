import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to Record'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Help', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ambient mode pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic, size: 18, color: Colors.black54),
                            SizedBox(width: 8),
                            Text(
                              'Ambient mode',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Timer
                      Obx(
                        () => Text(
                          '${controller.globalDuration.value.inMinutes.toString().padLeft(2, '0')} : ${(controller.globalDuration.value.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Control buttons row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left small control
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey[100],
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.tune,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            // Large center mic
                            Obx(
                              () => controller.isCompletedRecording.value
                                  ? Material(
                                      shape: const CircleBorder(),
                                      elevation: 6,
                                      color: controller.isPlaying.value
                                          ? Colors.green
                                          : Colors.grey[800],
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          if (controller.isPlaying.value) {
                                            controller.pausePlaying();
                                          } else if (controller
                                              .isPaused
                                              .value) {
                                            controller.resumePlaying();
                                          } else {
                                            controller.startPlaying();
                                          }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Icon(
                                            controller.isPlaying.value
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Material(
                                      shape: const CircleBorder(),
                                      elevation: 6,
                                      color: controller.isRecording.value
                                          ? Colors.red
                                          : Colors
                                                .grey[800], // slightly darker neutral for focal button
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          controller.toggleRecording();
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Icon(
                                            controller.isRecording.value
                                                ? Icons.stop
                                                : Icons.mic,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 28),
                            Obx(
                              () => CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey[100],
                                child: IconButton(
                                  onPressed: () {
                                    controller.isCompletedRecording.value ? controller.reset() : null;
                                  },
                                  icon: Icon(
                                    controller.isCompletedRecording.value
                                        ? Icons.refresh
                                        : Icons.location_on,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
