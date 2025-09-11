import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckInPointModel {
  final String id;
  final LatLng location;
  final double radiusMeters;
  final DateTime createdAt;
  final String createdBy;

  CheckInPointModel({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'lat': location.latitude,
    'lng': location.longitude,
    'radiusMeters': radiusMeters,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory CheckInPointModel.fromMap(Map<String, dynamic> map) {
    return CheckInPointModel(
      id: map['id'] as String,
      location: LatLng((map['lat'] as num).toDouble(), (map['lng'] as num).toDouble()),
      radiusMeters: (map['radiusMeters'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdBy: map['createdBy'] as String,
    );
  }
}
