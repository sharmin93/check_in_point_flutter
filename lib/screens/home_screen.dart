import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/check_in_provider.dart';
import '../services/location_service.dart';
import '../widgets/fake_location_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentLocation;
  StreamSubscription<Position>? _posSub;
  LatLng? _pickedLatLng;
  double _radius = 50;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final ok = await LocationService.isPermissionGranted();
    if (!ok) return;
    final pos = await LocationService.getCurrentPosition();
    setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));

    _posSub = LocationService.getPositionStream().listen((p) {
      setState(() => _currentLocation = LatLng(p.latitude, p.longitude));
      context.read<CheckInProvider>().checkOutIfOutside(
        _userId,
        _currentLocation!,
      );
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    final active = provider.activePoint;

    final markers = <Marker>{};
    if (_currentLocation != null) {
      markers.add(
        Marker(markerId: MarkerId('me'), position: _currentLocation!),
      );
    }
    if (_pickedLatLng != null) {
      markers.add(
        Marker(markerId: MarkerId('picked'), position: _pickedLatLng!),
      );
    }
    if (active != null) {
      markers.add(
        Marker(markerId: MarkerId('active'), position: active.location),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('CheckInApp'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(child: Text('Live: ${provider.liveCount}')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentLocation == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 16,
                    ),
                    markers: markers,
                    onTap: (latLng) => setState(() => _pickedLatLng = latLng),
                    circles: active != null
                        ? {
                            Circle(
                              circleId: CircleId('active-radius'),
                              center: active.location,
                              radius: active.radiusMeters,
                              fillColor: Colors.blue.withOpacity(0.15),
                              strokeColor: Colors.blue,
                              strokeWidth: 2,
                            ),
                          }
                        : {},
                  ),
          ),
          _buildControls(provider),
          FakeLocationWidget(
            onLocationSet: (latlng) {
              setState(() => _currentLocation = latlng);
              context.read<CheckInProvider>().checkOutIfOutside(_userId, latlng);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(CheckInProvider provider) {
    final active = provider.activePoint;
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          if (active == null) ...[
            Text('Tap map to pick a check-in point'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 500,
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text('${_radius.toInt()}m'),
              ],
            ),
            ElevatedButton(
              onPressed: _pickedLatLng == null
                  ? null
                  : () async {
                      await provider.createCheckInPoint(
                        location: _pickedLatLng!,
                        radiusMeters: _radius,
                        createdBy: _userId,
                      );
                    },
              child: Text('Create Check-in Point'),
            ),
          ] else ...[
            Text(
              'Active check-in by ${active.createdBy} — Radius ${active.radiusMeters.toInt()}m',
            ),
            ElevatedButton(
              onPressed: () async {
                if (_currentLocation == null) return;
                final success = await provider.tryCheckIn(
                  _userId,
                  _currentLocation!,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Check-in successful' : 'Not within radius',
                    ),
                  ),
                );
              },
              child: Text('Check In'),
            ),
            ElevatedButton(
              onPressed: provider.activePoint?.createdBy == _userId
                  ? () async => await provider.removeCheckInPoint()
                  : null,
              child: Text('Remove (owner)'),
            ),
          ],
          SizedBox(height: 8),
          Text('Live check-ins: ${provider.liveCount}'),
        ],
      ),
    );
  }
}
