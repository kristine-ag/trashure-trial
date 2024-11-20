import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:trashure/components/firebase_options.dart';

class ContactSetupScreen extends StatefulWidget {
  final String userId;

  const ContactSetupScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _ContactSetupScreenState createState() => _ContactSetupScreenState();
}

class _ContactSetupScreenState extends State<ContactSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  LatLng? _selectedLocation;
  GoogleMapController? mapController;
  String? currentAddress;
  String? _selectedArea;
  final Set<Marker> _markers = {};
  final List<String> _areas = [
    'POBLACION',
    'TALOMO',
    'AGDAO',
    'BUHANGIN',
    'BUNAWAN',
    'PAQUIBATO',
    'BAGUIO',
    'CALINAN',
    'MARILOG',
    'TORIL',
    'TUGBOK'
  ];
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);

  @override
  void dispose() {
    _contactController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception("Timeout while fetching address."),
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formattedAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        _updateAddressAndArea(formattedAddress);
      } else {
        await _fetchAddressUsingGoogleAPI(position);
      }
    } catch (e) {
      print('Error fetching address with geocoding: $e');
      await _fetchAddressUsingGoogleAPI(position);
    }
  }

  Future<void> _fetchAddressUsingGoogleAPI(LatLng position) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'];
          _updateAddressAndArea(formattedAddress);
        } else {
          _showAlertDialog('No address found.');
        }
      } else {
        _showAlertDialog('Error fetching address.');
      }
    } catch (e) {
      print('Error fetching address using Google API: $e');
      _showAlertDialog('Error fetching address: $e');
    }
  }

  void _updateAddressAndArea(String formattedAddress) {
    setState(() {
      currentAddress = formattedAddress;
      _addressController.text = formattedAddress;

      for (var area in _areas) {
        if (formattedAddress.toUpperCase().contains(area)) {
          _selectedArea = area;
          break;
        }
      }
    });
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _addMarker(LatLng position, String address) {
    setState(() {
      _markers.clear();
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

  Future<void> _saveContactInfo() async {
    if (_formKey.currentState?.validate() != true) {
      _showAlertDialog('Please complete all required fields.');
      return;
    }

    if (_contactController.text.isEmpty) {
      _showAlertDialog('Please enter your contact number.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'contact': _contactController.text,
        'address': _addressController.text,
        'landmark': _landmarkController.text,
        'location': _selectedLocation != null
            ? GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude)
            : null,
        'area': _selectedArea?.toLowerCase(),
      }, SetOptions(merge: true));
    } else {
      _showAlertDialog("User not logged in. Please log in and try again.");
    }

    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Contact Information')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 700;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWideScreen
                ? Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          height: MediaQuery.of(context).size.height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                            initialCameraPosition: CameraPosition(
                              target: _initialPosition,
                              zoom: 15,
                            ),
                            markers: _markers,
                            onTap: (LatLng position) async {
                              _addMarker(position,
                                  '${position.latitude}, ${position.longitude}');
                              await _getAddressFromLatLng(position);
                              setState(() {
                                _selectedLocation = position;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _contactController,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your contact number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Address (PLEASE CLICK ON THE MAP)',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _landmarkController,
                                  decoration: InputDecoration(
                                    labelText: 'Landmark (e.g., House number)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  value: _selectedArea,
                                  items: _areas
                                      .map((area) => DropdownMenuItem(
                                            value: area,
                                            child: Text(area),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedArea = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'District',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a district';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20.0),
                                ElevatedButton(
                                  onPressed: _saveContactInfo,
                                  child: Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[800],
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onTap: (LatLng position) async {
                            _addMarker(position,
                                '${position.latitude}, ${position.longitude}');
                            await _getAddressFromLatLng(position);
                            setState(() {
                              _selectedLocation = position;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _contactController,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your contact number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Address (PLEASE CLICK ON THE MAP)',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _landmarkController,
                                  decoration: InputDecoration(
                                    labelText: 'Landmark (e.g., House number)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  value: _selectedArea,
                                  items: _areas
                                      .map((area) => DropdownMenuItem(
                                            value: area,
                                            child: Text(area),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedArea = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'District',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a district';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20.0),
                                ElevatedButton(
                                  onPressed: _saveContactInfo,
                                  child: Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[800],
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
