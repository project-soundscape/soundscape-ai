class Soundscape {
  final String id;
  final String name;
  final String description;
  final String category;
  final String audioUrl;
  final String imageUrl;
  final Duration duration;

  const Soundscape({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
  });

  factory Soundscape.fromJson(Map<String, dynamic> json) {
    return Soundscape(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      audioUrl: json['audioUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      duration: Duration(seconds: json['duration'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'duration': duration.inSeconds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Soundscape &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.audioUrl == audioUrl &&
      other.imageUrl == imageUrl &&
      other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      audioUrl.hashCode ^
      imageUrl.hashCode ^
      duration.hashCode;
  }

  @override
  String toString() {
    return 'Soundscape(id: $id, name: $name, category: $category, duration: $duration)';
  }
}