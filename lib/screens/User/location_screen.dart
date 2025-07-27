import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;
  LatLng _center = LatLng(33.6844, 73.0479); // Default location
  Set<Marker> _markers = {};
  double _searchRadius = 10.0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
    });

    _loadNearbyDonors();
  }

  void _loadNearbyDonors() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
      if (_currentPosition == null) return;

      setState(() {
        _markers.clear();
        for (var doc in snapshot.docs) {
          var data = doc.data();

          if (data['SelectedUserType'] == 'Donor' &&
              data['isApproved'] == true &&
              data.containsKey('latitude') &&
              data.containsKey('longitude')) {

            double lat = data['latitude']?.toDouble();
            double lng = data['longitude']?.toDouble();
            String name = data['name'] ?? 'Donor';
            String phone = data['PhoneNo'] ?? 'N/A';

            double distance = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            );

            if (distance <= _searchRadius) {
              _markers.add(Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: 'Tap to view details',
                  onTap: () {
                    _showDonorDialog(name, phone, lat, lng, distance);
                  },
                ),
              ));
            }
          }
        }
      });
    });
  }

  void _showDonorDialog(String name, String phone, double lat, double lng, double distance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Phone: $phone"),
            Text("Distance: ${distance.toStringAsFixed(2)} km"),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              icon: Icon(Icons.directions),
              label: Text("Navigate"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Donors"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          if (_currentPosition != null)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Text("Search Radius: "),
                  Expanded(
                    child: Slider(
                      value: _searchRadius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: "${_searchRadius.round()} km",
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                          _loadNearbyDonors();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
