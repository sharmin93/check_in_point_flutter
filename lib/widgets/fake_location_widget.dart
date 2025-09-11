
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FakeLocationWidget extends StatefulWidget{
  final void Function(LatLng) onLocationSet;
  const FakeLocationWidget({super.key, required this.onLocationSet});

  @override
  State<FakeLocationWidget> createState() => _FakeLocationWidgetState();
}

class _FakeLocationWidgetState extends State<FakeLocationWidget> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  @override
  Widget build(BuildContext context) {
   return ExpansionTile(
     title: Text('Fake GPS (Testing)'),
     children: [
       Padding(
         padding: const EdgeInsets.all(8.0),
         child: Column(
           children: [
             TextField(
               controller: _latController,
               decoration: InputDecoration(labelText: 'Latitude'),
               keyboardType: TextInputType.number,
             ),
             TextField(
               controller: _lngController,
               decoration: InputDecoration(labelText: 'Longitude'),
               keyboardType: TextInputType.number,
             ),
             SizedBox(height: 8),
             ElevatedButton(
               onPressed: () {
                 final lat = double.tryParse(_latController.text);
                 final lng = double.tryParse(_lngController.text);
                 if (lat != null && lng != null) {
                   widget.onLocationSet(LatLng(lat, lng));
                 }
               },
               child: Text('Set Fake Location'),
             ),
           ],
         ),
       )
     ],
   );
  }
}
