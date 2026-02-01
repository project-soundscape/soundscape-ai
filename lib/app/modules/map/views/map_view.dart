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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 44,
          child: TextField(
            controller: controller.textController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              hintText: 'Search map...',
              hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 20, color: isDark ? Colors.grey[300] : Colors.grey),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black),
            textAlignVertical: TextAlignVertical.center,
            cursorColor: Colors.teal,
          ),
        ),
        backgroundColor: isDark ? null : Colors.white,
        elevation: 0.5,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.teal),
                onPressed: () => _showFilterModal(context),
              ),
              // Filter active indicator
              Obx(() {
                final isDefault = controller.filterOptions.value.status == 'All' && 
                                  controller.filterOptions.value.minConfidence == 0.0 &&
                                  controller.filterOptions.value.startDate == null;
                return isDefault ? const SizedBox.shrink() : Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                );
              }),
            ],
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
                urlTemplate: isDark 
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
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
                      radius: 10,
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
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: (controller.currentHeading.value * (3.14159 / 180)),
                            child: CustomPaint(
                              size: const Size(60, 60),
                              painter: DirectionPainter(),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Navigation Controls
          Positioned(
            bottom: controller.visibleRecordings.isEmpty ? 32 : 200,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  foregroundColor: Colors.teal,
                  onPressed: controller.zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  foregroundColor: Colors.teal,
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

          // Nearby Recordings Carousel
          if (controller.visibleRecordings.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              height: 150,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: controller.visibleRecordings.length,
                itemBuilder: (context, index) {
                  final rec = controller.visibleRecordings[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.toNamed(Routes.DETAILS, arguments: rec),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.graphic_eq, color: Colors.teal, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.commonName ?? 'Unidentified Sound',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('MMM d, h:mm a').format(rec.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (rec.confidence != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        "${(rec.confidence! * 100).toInt()}%",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.greenAccent : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  _buildBadge(context, Icons.timer_outlined, "${rec.duration.inSeconds}s"),
                                  const SizedBox(width: 12),
                                  _buildBadge(context, Icons.location_on_outlined, "${rec.latitude?.toStringAsFixed(3)}, ${rec.longitude?.toStringAsFixed(3)}"),
                                  const Spacer(),
                                  Text(
                                    "Details",
                                    style: TextStyle(
                                      color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: isDark ? Colors.tealAccent : Colors.teal.shade700),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

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

  void _showFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Obx(() {
          final filters = controller.filterOptions.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  TextButton(
                    onPressed: controller.resetFilters,
                    child: const Text('Reset', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['All', 'Processed', 'Pending', 'Uploaded'].map((status) {
                  final isSelected = filters.status == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: Colors.teal.withOpacity(0.2),
                    backgroundColor: isDark ? Colors.grey[800] : null,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal : (isDark ? Colors.grey[300] : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    onSelected: (_) => controller.updateFilterStatus(status),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              Text('Minimum Confidence', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: filters.minConfidence,
                      min: 0.0,
                      max: 0.9,
                      divisions: 9,
                      label: "${(filters.minConfidence * 100).toInt()}%",
                      activeColor: Colors.teal,
                      onChanged: controller.updateMinConfidence,
                    ),
                  ),
                  Text("${(filters.minConfidence * 100).toInt()}%+", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              
              const SizedBox(height: 24),
              Text('Date Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: filters.startDate != null && filters.endDate != null 
                        ? DateTimeRange(start: filters.startDate!, end: filters.endDate!) 
                        : null,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark 
                            ? const ColorScheme.dark(primary: Colors.teal, surface: Color(0xFF1E1E1E))
                            : const ColorScheme.light(primary: Colors.teal),
                        ),
                        child: child!,
                      );
                    }
                  );
                  if (picked != null) {
                    controller.updateDateRange(picked.start, picked.end);
                  }
                },
                icon: Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                label: Text(
                  filters.startDate != null 
                    ? "${DateFormat.MMMd().format(filters.startDate!)} - ${DateFormat.MMMd().format(filters.endDate!)}"
                    : "Select Date Range",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DirectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue.withValues(alpha: 0.6),
          Colors.blue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(size.width / 2, size.height / 2);
    path.relativeLineTo(-size.width / 4, -size.height / 2);
    path.relativeLineTo(size.width / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
