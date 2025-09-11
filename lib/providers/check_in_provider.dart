import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/check_in_point_model.dart';

class CheckInProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CheckInPointModel? _activePoint;

  CheckInPointModel? get activePoint => _activePoint;
  int _liveCount = 0;
  int get liveCount => _liveCount;

  StreamSubscription? _pointSub;
  StreamSubscription? _checkInSub;

  CheckInProvider() {
    _listenToActivePoint();
  }

  void _listenToActivePoint() {
    _pointSub = _db.collection('checkInPoint').limit(1).snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _activePoint = CheckInPointModel.fromMap(data);
        notifyListeners();
        _listenToLiveCheckins();
      } else {
        _activePoint = null;
        _liveCount = 0;
        notifyListeners();
      }
    });
  }

  void _listenToLiveCheckins() {
    if (_activePoint == null) return;
    _checkInSub?.cancel();
    _checkInSub = _db
        .collection('checkinPoint')
        .doc(_activePoint!.id)
        .collection('checkins')
        .snapshots()
        .listen((snapshot) {
      _liveCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  Future<void> createCheckInPoint({
    required LatLng location,
    required double radiusMeters,
    required String createdBy,
  }) async {
    // Remove any existing point first
    final existing = await _db.collection('checkinPoint').get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    final newPoint = CheckInPointModel(
      id: Uuid().v4(),
      location: location,
      radiusMeters: radiusMeters,
      createdAt: DateTime.now().toUtc(),
      createdBy: createdBy,
    );

    await _db.collection('checkinPoint').doc(newPoint.id).set(newPoint.toMap());
  }

  Future<void> removeCheckInPoint() async {
    if (_activePoint != null) {
      await _db.collection('checkinPoint').doc(_activePoint!.id).delete();
      _activePoint = null;
      _liveCount = 0;
      notifyListeners();
    }
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const R = 6371000; // metres
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;

    final hav = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return R * c;
  }

  Future<bool> tryCheckIn(String userId, LatLng userLocation) async {
    final point = _activePoint;
    if (point == null) return false;

    final dist = _distanceMeters(point.location, userLocation);
    if (dist <= point.radiusMeters) {
      await _db.collection('checkinPoint').doc(point.id).collection('checkins').doc(userId).set({
        'userId': userId,
        'lat': userLocation.latitude,
        'lng': userLocation.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    }
    return false;
  }

  Future<void> checkOutIfOutside(String userId, LatLng userLocation) async {
    final point = _activePoint;
    if (point == null) return;
    final dist = _distanceMeters(point.location, userLocation);
    if (dist > point.radiusMeters) {
      await _db.collection('checkinPoint').doc(point.id).collection('checkins').doc(userId).delete();
    }
  }

  @override
  void dispose() {
    _pointSub?.cancel();
    _checkInSub?.cancel();
    super.dispose();
  }
}

