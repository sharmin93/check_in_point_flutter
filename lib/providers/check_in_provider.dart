import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';


import '../models/check_in_entry.dart';
import '../models/check_in_point.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInPoint? _activePoint;
  CheckInPoint? get activePoint => _activePoint;

  final List<CheckInEntry> _checkIns = [];
  List<CheckInEntry> get checkIns => List.unmodifiable(_checkIns);

  LatLng? _currentLocation;
  LatLng? get currentLocation => _currentLocation;

  LatLng? _pickedLocation;
  LatLng? get pickedLocation => _pickedLocation;

  int get liveCount => _checkIns.length;
  double _radius = 50; // default radius in meters
  double get radius => _radius;

  void setRadius(double value) {
    _radius = value;
    notifyListeners();
  }

  Future<void> loadFromHive() async {
    final box = await Hive.openBox('checkinBox');

    // Handle activePoint
    final savedPoint = box.get('activePoint');
    if (savedPoint != null) {
      if (savedPoint is CheckInPoint) {
        _activePoint = savedPoint;
      } else if (savedPoint is Map) {
        // Migration from old Map format
        _activePoint = CheckInPoint(
          location: LatLng(
            savedPoint['latitude'] ?? 0.0,
            savedPoint['longitude'] ?? 0.0,
          ),
          radiusMeters: savedPoint['radiusMeters']?.toDouble() ?? 50,
          createdBy: savedPoint['createdBy'] ?? 'unknown',
          createdAt: savedPoint['createdAt'] != null
              ? DateTime.parse(savedPoint['createdAt'])
              : DateTime.now(),
        );
      }
    }

    // Handle checkIns
    final savedCheckIns = box.get('checkIns', defaultValue: []);
    _checkIns.clear();
    for (var c in savedCheckIns) {
      if (c is CheckInEntry) {
        _checkIns.add(c);
      } else if (c is Map) {
        _checkIns.add(CheckInEntry(
          userId: c['userId'] ?? 'unknown',
          time: c['time'] != null ? DateTime.parse(c['time']) : DateTime.now(),
        ));
      }
    }

    notifyListeners();
  }


  // Save state to Hive
  Future<void> _saveToHive() async {
    final box = await Hive.openBox('checkinBox');
    if (_activePoint != null) {
      await box.put('activePoint', _activePoint); // ✅ store object
    } else {
      await box.delete('activePoint');
    }
    await box.put('checkIns', _checkIns);
  }


  void updateCurrentLocation(LatLng newLocation, String userId) {
    _currentLocation = newLocation;
    checkOutIfOutside(userId, newLocation);
    notifyListeners();
  }

  void pickLocation(LatLng location) {
    _pickedLocation = location;
    notifyListeners();
  }

  Future<void> createCheckInPoint({
    required LatLng location,
    required double radiusMeters,
    required String createdBy,
  }) async {
    _activePoint = CheckInPoint(
      location: location,
      radiusMeters: radiusMeters,
      createdBy: createdBy,
    );
    _checkIns.clear();
    await _saveToHive();
    notifyListeners();
  }

  Future<bool> tryCheckIn(String userId, LatLng userLocation) async {
    if (_activePoint == null) return false;
    final distance = _distanceMeters(userLocation, _activePoint!.location);
    if (distance <= _activePoint!.radiusMeters) {
      if (!_checkIns.any((c) => c.userId == userId)) {
        _checkIns.add(CheckInEntry(userId: userId, time: DateTime.now()));
        await _saveToHive();
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void checkOutIfOutside(String userId, LatLng userLocation) async {
    if (_activePoint == null) return;
    final distance = _distanceMeters(userLocation, _activePoint!.location);
    if (distance > _activePoint!.radiusMeters) {
      _checkIns.removeWhere((c) => c.userId == userId);
      await _saveToHive();
      notifyListeners();
    }
  }

  Future<void> removeCheckInPoint() async {
    _activePoint = null;
    _checkIns.clear();
    await _saveToHive();
    notifyListeners();
  }

  // Haversine distance (in meters)
  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000; // meters
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final hav =
        (sin(dLat / 2) * sin(dLat / 2)) +
            (sin(dLon / 2) * sin(dLon / 2)) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}
