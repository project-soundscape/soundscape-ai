import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_pages.dart';
import '../controllers/map_controller.dart';
import '../providers/cached_tile_provider.dart';

class MapView extends GetView<SoundMapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<SoundMapController>()) {
      Get.put(SoundMapController());
    } else {
      controller.loadMarkers();
    }

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 44,
          child: TextField(
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              hintText: 'Search map...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            style: const TextStyle(fontSize: 16),
            textAlignVertical: TextAlignVertical.center,
            cursorColor: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.teal),
            onPressed: () {
              Get.snackbar(
                'Filter',
                'Filter options coming soon!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() => Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: controller.initialCenter.value,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.soundscape.frontend',
                tileProvider: CachedTileProvider(),
              ),
              CircleLayer(
                circles: [
                  if (controller.currentUserLocation.value != null)
                    CircleMarker(
                      point: controller.currentUserLocation.value!,
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderStrokeWidth: 1,
                      borderColor: Colors.blue.withValues(alpha: 0.5),
                      radius: 10, // 10m radius
                      useRadiusInMeter: true,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...controller.markers,
                  if (controller.currentUserLocation.value != null)
                    Marker(
                      point: controller.currentUserLocation.value!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Navigation Controls
          Positioned(
            bottom: 180,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal[800],
                  onPressed: controller.zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal[800],
                  onPressed: controller.zoomOut,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'myLoc',
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  onPressed: controller.centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Nearby Recordings List
          if (controller.visibleRecordings.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.visibleRecordings.length,
                itemBuilder: (context, index) {
                  final rec = controller.visibleRecordings[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          // Center map on item first? Or go to details?
                          // Let's go to details as per likely intent.
                          Get.toNamed(Routes.DETAILS, arguments: rec);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                    child: const Icon(Icons.music_note, color: Colors.teal),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.commonName ?? 'Unknown Sound',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat.yMMMd().format(rec.timestamp),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (rec.status == 'processed')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text('Identified', style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text('Pending', style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Loading Overlay
          if (controller.isLoading.value)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      )),
    );
  }
}
