import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/location_service.dart';
import '../../../routes/app_pages.dart';

class SoundMapController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final LocationService _locationService = Get.find<LocationService>();
  
  final markers = <Marker>[].obs;
  final visibleRecordings = <Recording>[].obs;
  final mapController = MapController();
  
  final Rx<LatLng> initialCenter = LatLng(0, 0).obs; 
  final Rx<LatLng?> currentUserLocation = Rx<LatLng?>(null);
  
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  StreamSubscription<Position>? _positionSubscription;

  @override
  void onInit() {
    super.onInit();
    _determineInitialPosition();
    loadMarkers();
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }

  Future<void> _determineInitialPosition() async {
    isLoading.value = true;
    try {
      // 1. Request permission explicitly
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }

      if (status.isGranted) {
        // Start streaming for high accuracy
        _startLocationTracking();
        
        // Also get immediate position for initial centering
        try {
          final pos = await _locationService.getCurrentLocation();
          if (pos != null) {
            final latLng = LatLng(pos.latitude, pos.longitude);
            initialCenter.value = latLng;
            currentUserLocation.value = latLng;
            _sortRecordingsByDistance();
            try {
              mapController.move(latLng, 15.0);
            } catch (_) {}
          }
        } catch (e) {
          print("Map: Initial location error: $e");
        }
      } else {
         // Fallback to latest recording if no permission
         _fallbackToRecordings();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      (Position position) {
        final latLng = LatLng(position.latitude, position.longitude);
        currentUserLocation.value = latLng;
        _sortRecordingsByDistance();
        
        // If it's the very first time we get a location and center is 0,0, move there
        if (initialCenter.value.latitude == 0 && initialCenter.value.longitude == 0) {
          initialCenter.value = latLng;
          try {
            mapController.move(latLng, 15.0);
          } catch (_) {}
        }
      },
      onError: (e) => print("Location Stream Error: $e"),
    );
  }

  void _fallbackToRecordings() {
    final recordings = _storageService.getRecordings();
    if (recordings.isNotEmpty) {
      final latest = recordings.first;
      if (latest.latitude != null && latest.longitude != null) {
        initialCenter.value = LatLng(latest.latitude!, latest.longitude!);
      }
    }
  }

  void loadMarkers([String? query]) {
    var recordings = _storageService.getRecordings();
    
    // Filter if query exists
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      recordings = recordings.where((rec) {
        final name = rec.commonName?.toLowerCase() ?? '';
        final notes = rec.notes?.toLowerCase() ?? '';
        final tags = rec.tags.join(' ').toLowerCase();
        return name.contains(lowerQuery) || notes.contains(lowerQuery) || tags.contains(lowerQuery);
      }).toList();
    }

    markers.clear();
    visibleRecordings.assignAll(recordings);
    _sortRecordingsByDistance();
    
    // Only update center on first load (no query) if we haven't found user location
    if ((query == null || query.isEmpty) && recordings.isNotEmpty && initialCenter.value == LatLng(0, 0)) {
      final first = recordings.first;
      if (first.latitude != null && first.longitude != null) {
        initialCenter.value = LatLng(first.latitude!, first.longitude!);
      }
    }

    for (var rec in recordings) {
      if (rec.latitude != null && rec.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(rec.latitude!, rec.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                Get.toNamed(Routes.DETAILS, arguments: rec);
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }
    }
  }

  void _sortRecordingsByDistance() {
    if (currentUserLocation.value == null) return;
    
    visibleRecordings.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;
      
      final distA = Geolocator.distanceBetween(
        currentUserLocation.value!.latitude, currentUserLocation.value!.longitude, 
        a.latitude!, a.longitude!
      );
      final distB = Geolocator.distanceBetween(
        currentUserLocation.value!.latitude, currentUserLocation.value!.longitude, 
        b.latitude!, b.longitude!
      );
      return distA.compareTo(distB);
    });
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    loadMarkers(val);
  }

  void zoomIn() {
    try {
      mapController.move(mapController.camera.center, mapController.camera.zoom + 1);
    } catch (_) {}
  }

  void zoomOut() {
    try {
      mapController.move(mapController.camera.center, mapController.camera.zoom - 1);
    } catch (_) {}
  }

  void centerOnUser() {
    if (currentUserLocation.value != null) {
      try {
        mapController.move(currentUserLocation.value!, 18.0);
      } catch (_) {}
    } else {
      _determineInitialPosition(); // Try fetching again
    }
  }
}