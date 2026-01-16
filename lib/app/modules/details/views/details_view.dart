import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../controllers/details_controller.dart';

class DetailsView extends GetView<DetailsController> {
  const DetailsView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(child: Text(controller.recording.commonName ?? 'Processing...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                             child: Text(
                               '${controller.recording.duration.inSeconds}s',
                               style: TextStyle(color: Colors.blue[900]),
                             ),
                           )
                         ],
                       ),
                       const SizedBox(height: 20),
                       // Waveform 
                       Container(
                         height: 100,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Colors.grey[50],
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey[200]!)
                         ),
                         child: AudioFileWaveforms(
                            size: Size(MediaQuery.of(context).size.width - 80, 100.0),
                            playerController: controller.waveformController,
                            enableSeekGesture: false,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: const PlayerWaveStyle(
                              fixedWaveColor: Colors.teal,
                              liveWaveColor: Colors.tealAccent,
                              spacing: 6,
                            ),
                         ),
                       ),
                       const SizedBox(height: 20),
                       Row(
                         children: [
                           Obx(() => ElevatedButton.icon(
                             onPressed: controller.togglePlay,
                             icon: Icon(controller.isPlaying.value ? Icons.pause : Icons.play_arrow),
                             label: Text(controller.isPlaying.value ? 'Pause' : 'Play'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.teal[50],
                               foregroundColor: Colors.teal,
                               elevation: 0,
                             ),
                           )),
                           const Spacer(),
                           OutlinedButton.icon(
                             onPressed: controller.exportAudio,
                             icon: const Icon(Icons.share),
                             label: const Text('Export'),
                           )
                         ],
                       )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Metadata
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Metadata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: (){}, 
                    icon: const Icon(Icons.edit, size: 16), 
                    label: const Text('Edit')
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildMetaItem('Location', '${controller.recording.latitude?.toStringAsFixed(4)}, ${controller.recording.longitude?.toStringAsFixed(4)}'),
              _buildMetaItem('Date & time', DateFormat.yMMMd().add_jm().format(controller.recording.timestamp)),
              _buildMetaItem('ID', controller.recording.id.substring(0, 8)),
              
              const SizedBox(height: 24),
              const Text('Map Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (controller.recording.latitude != null && controller.recording.longitude != null)
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(controller.recording.latitude!, controller.recording.longitude!),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static map feel
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.frontend',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(controller.recording.latitude!, controller.recording.longitude!),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
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
                   decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                   child: const Center(child: Text('No Location Data')),
                 ),
                 
               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: Obx(() => ElevatedButton(
                   onPressed: controller.isUploading.value ? null : controller.submitRecording,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF004D40),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: controller.isUploading.value 
                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : const Text('Submit for Analysis', style: TextStyle(fontSize: 16, color: Colors.white)),
                 )),
               )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
