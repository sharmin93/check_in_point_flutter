import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/check_in_provider.dart';
import '../services/location_service.dart';
import '../widgets/fake_location_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentLocation;
  StreamSubscription? _positionSubscription;
  LatLng? _pickedLatLng;
  double _radius = 50;
  final String _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final permissionGranted = await LocationService.isPermissionGranted();
    if (!permissionGranted) return;

    final position = await LocationService.getCurrentPosition();
    context.read<CheckInProvider>().updateCurrentLocation(
        LatLng(position.latitude, position.longitude), _userId);

    _positionSubscription = LocationService.getPositionStream().listen((position) {
      context.read<CheckInProvider>().updateCurrentLocation(
          LatLng(position.latitude, position.longitude), _userId);
    });
  }


  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    final active = provider.activePoint;
    final currentLocation = provider.currentLocation;
    final pickedLatLng = provider.pickedLocation;

    final markers = <Marker>{};
    if (_currentLocation != null) {
      markers.add(Marker(markerId: MarkerId('self'), position: _currentLocation!));
    }
    if (_pickedLatLng != null) {
      markers.add(Marker(markerId: MarkerId('picked'), position: _pickedLatLng!));
    }
    if (active != null) {
      markers.add(Marker(markerId: MarkerId('active'), position: active.location));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('CheckIn-Out App'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(child: Text('Live: ${provider.liveCount}')),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentLocation == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation,
                zoom: 16,
              ),
              markers: {
                if (currentLocation != null)
                  Marker(markerId: MarkerId('self'), position: currentLocation),
                if (provider.pickedLocation != null)
                  Marker(markerId: MarkerId('picked'), position: provider.pickedLocation!),
                if (active != null)
                  Marker(markerId: MarkerId('active'), position: active.location),
              },
              onTap: (latLng) => provider.pickLocation(latLng), // ✅ update provider
              circles: active != null
                  ? {
                Circle(
                  circleId: CircleId('active-radius'),
                  center: active.location,
                  radius: active.radiusMeters,
                  fillColor: Colors.blue.withOpacity(0.15),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                )
              }
                  : {},
            )

          ),
          _buildControls(context,provider),
          FakeLocationWidget(
            onLocationSet: (latLng) {
              provider.updateCurrentLocation(latLng, _userId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, CheckInProvider provider) {
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
                    value: provider.radius,
                    onChanged: (v) => provider.setRadius(v),
                  ),
                ),
                Text('${provider.radius.toInt()}m'),
              ],
            ),

            ElevatedButton(
              onPressed: provider.pickedLocation == null
                  ? null
                  : () async {
                await provider.createCheckInPoint(
                  location: provider.pickedLocation!,
                  radiusMeters: _radius,
                  createdBy: _userId,
                );
              },
              child: Text('Create Check-in Point'),
            ),
          ] else ...[
            Text(
              'Active check-in created by ${active.createdBy}\n'
                  'Radius: ${active.radiusMeters.toInt()}m',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            if (active.createdBy == _userId)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await provider.removeCheckInPoint();
                },
                child: Text('Remove (Owner)'),
              )
            else
              ElevatedButton(
                onPressed: provider.currentLocation == null
                    ? null
                    : () async {
                  final success = await provider.tryCheckIn(
                    _userId,
                    provider.currentLocation!,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      success
                          ? 'Check-in successful'
                          : 'Not within radius',
                    ),
                  ));
                },
                child: Text('Check In'),
              ),
          ],
          const SizedBox(height: 8),
          Text('Live check-ins: ${provider.liveCount}'),
        ],
      ),
    );
  }

}
