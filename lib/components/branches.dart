import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OnSiteScreen extends StatefulWidget {
  const OnSiteScreen({Key? key}) : super(key: key);

  @override
  _OnSiteScreenState createState() => _OnSiteScreenState();
}

class _OnSiteScreenState extends State<OnSiteScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _fetchBranchLocations();
  }
  
  Future<void> _fetchBranchLocations() async {
    try {
      final branchSnapshot = await FirebaseFirestore.instance.collection('branches').get();
      for (var branch in branchSnapshot.docs) {
        final data = branch.data();
        final GeoPoint location = data['location'];
        final String branchName = data['name'];
        final LatLng position = LatLng(location.latitude, location.longitude);

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(branchName),
              position: position,
              infoWindow: InfoWindow(title: branchName),
            ),
          );
        });
      }
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trashure - Branch Locations'),
        backgroundColor: Colors.green[700],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(7.0731, 125.6122), // Initial position
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}
