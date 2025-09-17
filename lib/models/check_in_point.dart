import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';

part 'check_in_point.g.dart';

@HiveType(typeId: 1)
class CheckInPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double radiusMeters;

  @HiveField(3)
  final String createdBy;

  @HiveField(4)
  final DateTime createdAt;

  CheckInPoint({
    required LatLng location,
    required this.radiusMeters,
    required this.createdBy,
    DateTime? createdAt,
  })  : latitude = location.latitude,
        longitude = location.longitude,
        createdAt = createdAt ?? DateTime.now();

  /// Convert back to Google Maps LatLng
  LatLng get location => LatLng(latitude, longitude);
}
