import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:trashure/components/appbar.dart'; // For location access

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  LatLng? currentPosition;
  String? currentAddress;
  final String googleApiKey = 'AIzaSyD1c6gdPl_vhxfXwcLQ87bQ-FRPL55eGF4'; // Add your API key here
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
  }

  Future<void> initializeMap() async {
    // Request location permission and get the user's current location
    await _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentPosition!,
                      zoom: 13,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        icon: BitmapDescriptor.defaultMarker,
                        position: currentPosition!,
                      ),
                    },
                    onTap: (LatLng tappedPosition) async {
                      setState(() {
                        currentPosition = tappedPosition;
                        currentAddress = "Fetching address...";
                      });
                      await _getAddressFromLatLng(tappedPosition);
                      mapController?.animateCamera(CameraUpdate.newLatLng(tappedPosition));
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.white,
                    child: currentAddress == null
                        ? const Center(
                            child: Text(
                              'Fetching address...',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Current Address:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentAddress!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  // Method to get the user's current location
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentAddress = 'Location services are disabled.';
      });
      return;
    }

    // Request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          currentAddress = 'Location permissions are denied.';
        });
        return;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Set the user's current position
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Fetch the address for the current location
    await _getAddressFromLatLng(currentPosition!);
  }

  // Method to get address from lat/lng using Google Geocoding API
  Future<void> _getAddressFromLatLng(LatLng position) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'];
          setState(() {
            currentAddress = formattedAddress;
          });
        } else {
          setState(() {
            currentAddress = 'No address found';
          });
        }
      } else {
        setState(() {
          currentAddress = 'Error fetching address: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        currentAddress = 'Error fetching address: $e';
      });
    }
  }
}
