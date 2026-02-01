import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/wiki_service.dart';
import '../../../routes/app_pages.dart';

class SoundMapController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final LocationService _locationService = Get.find<LocationService>();
  final WikiService _wikiService = Get.put(WikiService());
  
  final markers = <Marker>[].obs;
  final visibleRecordings = <Recording>[].obs;
  final mapController = MapController();
  
  final Rx<LatLng> initialCenter = LatLng(0, 0).obs; 
  final Rx<LatLng?> currentUserLocation = Rx<LatLng?>(null);
  final RxDouble currentHeading = 0.0.obs;
  
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final filterOptions = FilterOptions().obs;
  final textController = TextEditingController();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _headingSubscription;

  @override
  void onInit() {
    super.onInit();
    _determineInitialPosition();
    
    // Listen to changes
    ever(_storageService.recordings, (_) => loadMarkers());
    ever(searchQuery, (_) => loadMarkers());
    ever(filterOptions, (_) => loadMarkers());
    
    loadMarkers();
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    textController.dispose();
    super.onClose();
  }

  Future<void> _determineInitialPosition() async {
    isLoading.value = true;
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }

      if (status.isGranted) {
        _startLocationTracking();
        _startHeadingTracking();
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

  void _startHeadingTracking() {
    _headingSubscription?.cancel();
    _headingSubscription = _locationService.getHeadingStream()?.listen((event) {
      if (event.heading != null) {
        currentHeading.value = event.heading!;
      }
    });
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

  void loadMarkers([String? _]) {
    var recordings = _storageService.getRecordings();
    final query = searchQuery.value;
    final filters = filterOptions.value;
    
    // 1. Text Search
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      recordings = recordings.where((rec) {
        final name = rec.commonName?.toLowerCase() ?? '';
        final notes = rec.notes?.toLowerCase() ?? '';
        final tags = rec.tags.join(' ').toLowerCase();
        return name.contains(lowerQuery) || notes.contains(lowerQuery) || tags.contains(lowerQuery);
      }).toList();
    }
    
    // 2. Apply Filters
    if (filters.status != 'All') {
       recordings = recordings.where((r) => r.status.toLowerCase() == filters.status.toLowerCase()).toList();
    }
    
    if (filters.minConfidence > 0) {
       recordings = recordings.where((r) => (r.confidence ?? 0) >= filters.minConfidence).toList();
    }
    
    if (filters.startDate != null) {
       recordings = recordings.where((r) => r.timestamp.isAfter(filters.startDate!)).toList();
    }
    
    if (filters.endDate != null) {
       recordings = recordings.where((r) => r.timestamp.isBefore(filters.endDate!.add(const Duration(days: 1)))).toList();
    }

    markers.clear();
    visibleRecordings.assignAll(recordings);
    _sortRecordingsByDistance();
    
    for (var rec in recordings) {
      if (rec.latitude != null && rec.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(rec.latitude!, rec.longitude!),
            width: 50,
            height: 50,
            child: _buildMarkerChild(rec),
          ),
        );
      }
    }
  }
  
  Widget _buildMarkerChild(Recording rec) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.DETAILS, arguments: rec);
      },
      child: rec.commonName != null 
          ? FutureBuilder<String?>(
              future: _wikiService.getBirdImage(rec.commonName!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                    ),
                  );
                }
                return _defaultMarker();
              },
            )
          : _defaultMarker(),
    );
  }

  Widget _defaultMarker() {
    return const Icon(Icons.location_on, color: Colors.red, size: 50);
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
  
  void updateFilterStatus(String status) {
    filterOptions.update((val) {
      val?.status = status;
    });
  }
  
  void updateMinConfidence(double confidence) {
    filterOptions.update((val) {
      val?.minConfidence = confidence;
    });
  }
  
  void updateDateRange(DateTime? start, DateTime? end) {
    filterOptions.update((val) {
      val?.startDate = start;
      val?.endDate = end;
    });
  }
  
  void resetFilters() {
    filterOptions.value = FilterOptions();
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
  }
  
  void clearSearch() {
    searchQuery.value = '';
    textController.clear();
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
      _determineInitialPosition(); 
    }
  }
}

class FilterOptions {
  String status = 'All'; 
  double minConfidence = 0.0;
  DateTime? startDate;
  DateTime? endDate;
}