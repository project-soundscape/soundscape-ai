import 'dart:convert';

class Recording {
  final String id;
  String path;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final Duration duration;
  List<String> tags;
  String status; // 'pending', 'uploaded', 'processed'
  String? commonName;
  double? confidence;
  String? notes;
  String? streamUrl;
  Map<String, double>? predictions;

  Recording({
    required this.id,
    required this.path,
    this.latitude,
    this.longitude,
    required this.timestamp,
    required this.duration,
    this.tags = const [],
    this.status = 'pending',
    this.commonName,
    this.confidence,
    this.notes,
    this.streamUrl,
    this.predictions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inMilliseconds,
      'tags': tags,
      'status': status,
      'commonName': commonName,
      'confidence': confidence,
      'notes': notes,
      'streamUrl': streamUrl,
      'predictions': predictions,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'],
      path: map['path'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
      duration: Duration(milliseconds: map['duration']),
      tags: List<String>.from(map['tags']),
      status: map['status'],
      commonName: map['commonName'],
      confidence: map['confidence'],
      notes: map['notes'],
      streamUrl: map['streamUrl'],
      predictions: map['predictions'] != null 
          ? Map<String, double>.from(map['predictions']) 
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Recording.fromJson(String source) => Recording.fromMap(json.decode(source));

  bool get isLocal => !path.startsWith('http');
}
