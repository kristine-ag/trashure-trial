import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // For address handling
import 'package:geolocator/geolocator.dart'; // For user location
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:trashure/components/appbar.dart'; // For environment variables

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  String? currentAddress;
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);
  final TextEditingController _defaultAddressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  final String googleApiKey = 'AIzaSyD1c6gdPl_vhxfXwcLQ87bQ-FRPL55eGF4';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await _getUserLocation());
  }

  @override
  void dispose() {
    _defaultAddressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  // Fetch the current user's location
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
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          currentAddress = 'Location permissions are denied.';
        });
        return;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Fetch the address for the current location
    await _getAddressFromLatLng(currentPosition!);

    // Move the map camera to the current position
    mapController?.animateCamera(CameraUpdate.newLatLng(currentPosition!));
    _addMarker(currentPosition!, currentAddress!);
  }

  // Method to get the address from LatLng using geocoding
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
            _defaultAddressController.text = formattedAddress;  // Set the fetched address in the TextField
          });
        } else {
          setState(() {
            currentAddress = 'No address found';
            _defaultAddressController.text = 'No address found';
          });
        }
      } else {
        setState(() {
          currentAddress = 'Error fetching address: ${response.statusCode}';
          _defaultAddressController.text = 'Error fetching address';
        });
      }
    } catch (e) {
      setState(() {
        currentAddress = 'Error fetching address: $e';
        _defaultAddressController.text = 'Error fetching address';
      });
    }
  }

  // Method to get LatLng from an address
  Future<void> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations[0];
        final latLng = LatLng(location.latitude, location.longitude);

        mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

        setState(() {
          _addMarker(latLng, address);
        });
      }
    } catch (e) {
      print('Error retrieving location: $e');
    }
  }

  // Add a marker on the map
  void _addMarker(LatLng position, String address) {
    setState(() {
      _markers.clear(); // Clear previous markers
      _markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(
          title: 'Selected Location',
          snippet: address,
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'CONFIRM YOUR ADDRESS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Default Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _defaultAddressController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter default address',
                            ),
                            onSubmitted: (value) {
                              _getLatLngFromAddress(value); // Fetch LatLng from address
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'House no., Landmark, etc.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _landmarkController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter landmark or house no.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: currentPosition ?? _initialPosition,
                          zoom: 15,
                        ),
                        markers: _markers,
                        onTap: (LatLng position) {
                          _addMarker(position, '${position.latitude}, ${position.longitude}');
                          _getAddressFromLatLng(position); // Fetch address from tapped location and update the TextField
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Back', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    final address = _defaultAddressController.text;
                    final landmark = _landmarkController.text;
                    final fullAddress = '$address, Landmark: $landmark';
                    Navigator.pop(context, fullAddress);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Next', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Trashure - Login Required',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You need to be logged in to confirm your address.',
              style: TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Login Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Center(
        child: Text('© 2024 Trashure', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
