import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_pages.dart';
import '../controllers/details_controller.dart';
import '../../map/providers/persistent_tile_provider.dart';

import '../../../data/services/audio_analysis_service.dart';

class DetailsView extends GetView<DetailsController> {
  const DetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analysisService = Get.find<AudioAnalysisService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip details'),
        backgroundColor: isDark ? null : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card
              Card(
                elevation: 0,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.recording.commonName ??
                                      'Processing...',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (controller.recording.predictions != null &&
                                    controller.recording.predictions!.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '+${controller.recording.predictions!.length - 1} more species detected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (controller.recording.confidence != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${(controller.recording.confidence! * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                           Obx(() => Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                             child: Text(
                               controller.isPlaying.value
                                 ? '-${controller.remainingTime.value.inMinutes.toString().padLeft(2, '0')}:${(controller.remainingTime.value.inSeconds % 60).toString().padLeft(2, '0')}'
                                 : '${controller.recording.duration.inSeconds}s',
                               style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
                             ),
                           )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Waveform
                      Container(
                        height: 150,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            AudioFileWaveforms(
                              size: Size(
                                MediaQuery.of(context).size.width - 80,
                                100.0,
                              ),
                              playerController: controller.waveformController,
                              enableSeekGesture: false,
                              waveformType: WaveformType.fitWidth,
                              playerWaveStyle: const PlayerWaveStyle(
                                fixedWaveColor: Colors.teal,
                                liveWaveColor: Colors.tealAccent,
                                spacing: 6,
                              ),
                            ),
                            // Detection Timeline Markers
                            Obx(() {
                              if (controller.timelineEvents.isEmpty) return const SizedBox(height: 20);
                              
                              final totalMs = controller.totalDuration.value.inMilliseconds > 0 
                                  ? controller.totalDuration.value.inMilliseconds 
                                  : controller.recording.duration.inMilliseconds;
                              final width = MediaQuery.of(context).size.width - 80;
                              
                              return SizedBox(
                                height: 20,
                                width: width,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: controller.timelineEvents.map((e) {
                                    final t = e['time'] as Duration;
                                    final label = e['label'] as String;
                                    final conf = e['confidence'] as double;
                                    
                                    if (totalMs == 0) return const SizedBox.shrink();
                                    final pct = t.inMilliseconds / totalMs;
                                    if (pct < 0 || pct > 1.0) return const SizedBox.shrink();
                                    
                                    return Positioned(
                                      left: (width * pct) - 10, // Center the icon
                                      child: Tooltip(
                                        message: "$label (${(conf * 100).toInt()}%) @ ${t.inSeconds}s",
                                        triggerMode: TooltipTriggerMode.tap,
                                        child: Icon(
                                          Icons.arrow_drop_up, 
                                          size: 20, 
                                          color: Colors.orange.withOpacity(0.8)
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            })
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Obx(
                            () => ElevatedButton.icon(
                              onPressed: controller.togglePlay,
                              icon: Icon(
                                controller.isPlaying.value
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                controller.isPlaying.value ? 'Pause' : 'Play',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[50],
                                foregroundColor: Colors.teal,
                                elevation: 0,
                              ),
                            ),
                          ),
                           const Spacer(),
                           OutlinedButton.icon(
                             onPressed: controller.exportAudio,
                             icon: const Icon(Icons.share),
                             label: const Text('Export'),
                           ),
                           const SizedBox(width: 12),
                           Obx(() => ElevatedButton.icon(
                             onPressed: controller.isScanning.value ? null : controller.scanFullFile,
                             icon: Icon(controller.isScanning.value ? Icons.hourglass_top : Icons.search),
                             label: const Text('Deep Scan'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.orange[50],
                               foregroundColor: Colors.orange[900],
                               elevation: 0,
                             ),
                           )),
                           if (controller.recording.streamUrl != null && controller.recording.streamUrl!.isNotEmpty)
                             Padding(
                               padding: const EdgeInsets.only(left: 12),
                               child: ElevatedButton.icon(
                                 onPressed: () => Get.toNamed(Routes.LIVE_STREAM, arguments: controller.recording.streamUrl),
                                 icon: const Icon(Icons.live_tv),
                                 label: const Text('Live Feed'),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.red[50],
                                   foregroundColor: Colors.red[900],
                                   elevation: 0,
                                 ),
                               ),
                             ),
                         ],
                       )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // SCAN PROGRESS
              Obx(() => controller.isScanning.value ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deep Scanning clip...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${(controller.scanProgress.value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: controller.scanProgress.value,
                      backgroundColor: Colors.orange[50],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ) : const SizedBox.shrink()),

              // SCAN RESULTS CARD
              Obx(() {
                if (controller.scanResults.isEmpty) return const SizedBox.shrink();
                final results = controller.scanResults.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[900] : Colors.orange[50]?.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.orange.withOpacity(0.2))),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                            SizedBox(width: 12),
                            Text('Deep Scan Findings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...results.take(10).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                              Text('${(e.value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              }),
              
              // YAMNet Analysis Card
              Obx(() {
                final isPlaying = controller.isPlaying.value;
                final livePredictions = analysisService.topPredictions;
                final hasStaticPredictions =
                    controller.recording.predictions != null &&
                    controller.recording.predictions!.isNotEmpty;

                // Show live predictions if they are available (even if not playing)
                // Otherwise fallback to static predictions from the recording object
                final bool useLive = livePredictions.isNotEmpty;

                if (!useLive && !hasStaticPredictions)
                  return const SizedBox.shrink();

                final List<MapEntry<String, double>> displayPredictions =
                    useLive
                    ? livePredictions
                    : (controller.recording.predictions?.entries.toList() ??
                          []);

                return Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPlaying ? 'Live Analysis' : 'Species Detected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.tealAccent : Colors.teal,
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(left: 8),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.teal,
                                ),
                              ),
                          ],
                        ),
                        
                        // Detection Summary Bar
                        if (!isPlaying && displayPredictions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat(
                                  icon: Icons.visibility,
                                  label: 'Species',
                                  value: '${displayPredictions.length}',
                                  color: Colors.blue,
                                  isDark: isDark,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                                ),
                                _buildStat(
                                  icon: Icons.star,
                                  label: 'Best Match',
                                  value: '${(displayPredictions.first.value * 100).toInt()}%',
                                  color: Colors.green,
                                  isDark: isDark,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                                ),
                                _buildStat(
                                  icon: Icons.check_circle,
                                  label: 'Confidence',
                                  value: displayPredictions.first.value >= 0.7 ? 'High' : 
                                         displayPredictions.first.value >= 0.4 ? 'Medium' : 'Low',
                                  color: displayPredictions.first.value >= 0.7 ? Colors.green :
                                         displayPredictions.first.value >= 0.4 ? Colors.orange : Colors.red,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        ...displayPredictions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final e = entry.value;
                          final score = e.value;
                          final isTop = index == 0;
                          
                          // Use index-based ranking colors
                          Color getColor() {
                            if (isTop) return Colors.green;
                            if (index == 1) return Colors.blue;
                            if (index == 2) return Colors.orange;
                            return Colors.grey;
                          }
                          
                          // Medal icons for top 3
                          Widget? getMedal() {
                            if (index == 0) return const Icon(Icons.emoji_events, color: Colors.amber, size: 20);
                            if (index == 1) return const Icon(Icons.emoji_events, color: Colors.grey, size: 18);
                            if (index == 2) return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 16);
                            return null;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isTop 
                                  ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.08))
                                  : (isDark ? Colors.grey[850] : Colors.grey[50]),
                                borderRadius: BorderRadius.circular(12),
                                border: isTop 
                                  ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5)
                                  : null,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (getMedal() != null) ...[
                                        getMedal()!,
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: TextStyle(
                                            fontWeight: isTop
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: isTop ? 16 : 14,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getColor().withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: getColor().withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          "${(score * 100).toInt()}%",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isTop ? 14 : 12,
                                            color: getColor(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: score),
                                    duration: Duration(milliseconds: 300 + (index * 100)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          backgroundColor: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                          color: getColor(),
                                          minHeight: isTop ? 12 : 8,
                                        ),
                                      );
                                    },
                                  ),
                                  if (isTop && !isPlaying) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Primary detection',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.green[300] : Colors.green[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }),

              // SPECIES INSIGHT CARD
              Obx(() {
                if (controller.isLoadingWiki.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final info = controller.speciesData.value;
                if (info == null) return const SizedBox.shrink();

                return Card(
                  elevation: 2,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  margin: const EdgeInsets.only(bottom: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info['imageUrl'] != null)
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: info['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['title'] ?? 'Unknown Bird',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              info['description'] ??
                                  'No description available.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Real World Options',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        controller.launchURL(info['pageUrl']),
                                    icon: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Wikipedia'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        controller.openEBird(info['title']),
                                    icon: const Icon(Icons.explore, size: 18),
                                    label: const Text('eBird'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Metadata
              const Text(
                'Metadata',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),
              _buildMetaItem(
                context,
                'Location',
                '${controller.recording.latitude?.toStringAsFixed(4)}, ${controller.recording.longitude?.toStringAsFixed(4)}',
              ),
              _buildMetaItem(
                context,
                'Date & time',
                DateFormat.yMMMd().add_jm().format(
                  controller.recording.timestamp,
                ),
              ),
              _buildMetaItem(
                context,
                'ID',
                controller.recording.id.substring(0, 8),
              ),

              const SizedBox(height: 24),
              const Text(
                'Map Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (controller.recording.latitude != null &&
                  controller.recording.longitude != null)
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          controller.recording.latitude!,
                          controller.recording.longitude!,
                        ),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ), // Static map feel
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDark 
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.soundscape.frontend',
                          tileProvider: PersistentTileProvider(),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                controller.recording.latitude!,
                                controller.recording.longitude!,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('No Location Data')),
                ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isUploading.value
                        ? null
                        : controller.submitRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isUploading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit for Analysis',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for detection statistics
  static Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
