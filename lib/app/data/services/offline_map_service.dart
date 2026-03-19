import 'dart:math';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

class OfflineMapService extends GetxService {
  final RxBool isDownloading = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxString status = "".obs;

  // Calculates map tiles for a given bounding box and zoom range
  Future<void> downloadRegion(double minLat, double minLng, double maxLat, double maxLng, {int minZoom = 13, int maxZoom = 15}) async {
    if (isDownloading.value) return;

    isDownloading.value = true;
    progress.value = 0.0;
    status.value = "Calculating tiles...";

    List<String> urls = [];
    for (int z = minZoom; z <= maxZoom; z++) {
      int minX = _lon2tilex(minLng, z);
      int maxX = _lon2tilex(maxLng, z);
      int minY = _lat2tiley(maxLat, z); // maxLat corresponds to minY
      int maxY = _lat2tiley(minLat, z);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          // Add both light and dark variations just in case
          urls.add('https://a.basemaps.cartocdn.com/light_all/$z/$x/$y.png');
          urls.add('https://a.basemaps.cartocdn.com/dark_all/$z/$x/$y.png');
        }
      }
    }

    status.value = "Downloading ${urls.length} tiles...";

    int downloaded = 0;
    final cacheManager = DefaultCacheManager();

    // Download in chunks concurrently
    const chunkSize = 20;
    for (int i = 0; i < urls.length; i += chunkSize) {
      if (!isDownloading.value) break; // Allow cancellation

      final end = (i + chunkSize < urls.length) ? i + chunkSize : urls.length;
      final chunkUrls = urls.sublist(i, end);

      await Future.wait(chunkUrls.map((url) async {
        try {
          // Check if already in cache before network call
          final fileInfo = await cacheManager.getFileFromCache(url);
          if (fileInfo == null) {
            await cacheManager.downloadFile(url);
          }
        } catch (e) {
          print("Failed to download tile: $url");
        }
      }));

      downloaded += chunkUrls.length;
      progress.value = downloaded / urls.length;
    }

    isDownloading.value = false;
    status.value = "Download complete!";

    // Clear status after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!isDownloading.value) status.value = "";
    });
  }

  void cancelDownload() {
    isDownloading.value = false;
    status.value = "Cancelled.";
  }

  // Math conversions from standard OSM tile math
  int _lon2tilex(double lon, int z) {
    return ((lon + 180.0) / 360.0 * pow(2.0, z)).floor();
  }

  int _lat2tiley(double lat, int z) {
    return ((1.0 - log(tan(lat * pi / 180.0) + 1.0 / cos(lat * pi / 180.0)) / pi) / 2.0 * pow(2.0, z)).floor();
  }
}
