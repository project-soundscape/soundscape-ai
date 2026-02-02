import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../../../data/services/audio_analysis_service.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final analysisService = Get.find<AudioAnalysisService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
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
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Main Action Button (Record/Review)
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
                          
                          const SizedBox(height: 24),
                          
                          // Top 5 Confidence Meters
                          SizedBox(
                            height: 200,
                            child: Obx(() {
                                final predictions = analysisService.topPredictions;
                                if (predictions.isEmpty) return const SizedBox.shrink();
                                
                                return ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: predictions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = predictions[index];
                                    final label = item.key;
                                    final score = item.value;
                                    
                                    // Highlight Speech in Red if high, others Teal
                                    final isSpeech = label == 'Speech';
                                    final isWarning = isSpeech && score > 0.7;
                                    final color = isWarning ? Colors.red : (isSpeech ? Colors.orange : Colors.teal);
                                    
                                    return Row(
                                      children: [
                                        SizedBox(
                                          width: 120, 
                                          child: Text(
                                            label, 
                                            style: TextStyle(
                                              fontSize: 12, 
                                              fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                                              color: isWarning ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(begin: 0, end: score),
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: value,
                                                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                                  color: color,
                                                  minHeight: 12,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            "${(score * 100).toInt()}%",
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                );
                            }),
                          ),
                        ]
                      ],
                    );
                  }
                }),
                
                const Spacer(),
                Obx(() => controller.isRecording.value 
                  ? const Text("Recording... Keep device steady.", style: TextStyle(color: Colors.grey))
                  : _buildNearbySection(context)
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.nearbyRecordings.isNotEmpty) ...[
          const Text(
            'NEARBY DISCOVERIES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.nearbyRecordings.length,
              itemBuilder: (context, index) {
                final rec = controller.nearbyRecordings[index];
                return GestureDetector(
                  onTap: () => Get.toNamed(Routes.DETAILS, arguments: rec),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.commonName ?? 'Unidentified',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.teal),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${rec.latitude?.toStringAsFixed(2)}, ${rec.longitude?.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}