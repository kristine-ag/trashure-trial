import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:trashure/components/booking_info.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng? _selectedLocation;
  String? _selectedAddress;
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAddress == null || _selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an address using the map.')),
        );
      } else {
        // Check if contact number already exists
        final contactSnapshot = await _firestore
            .collection('users')
            .where('contact', isEqualTo: _contactController.text)
            .get();

        if (contactSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Contact number already exists.')),
          );
        } else {
          await _completeSignup();
        }
      }
    }
  }

  // Opens map-based address selector
  Future<void> _openAddressSelector() async {
    LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSelectionScreen(
          initialPosition: _initialPosition,
          googleApiKey: googleMapsApiKey,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _getAddressFromLatLng(result); // Fetch and store the formatted address
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'];
          setState(() {
            _selectedAddress = formattedAddress;
            _addressController.text = formattedAddress; // Update address field
          });
        }
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> _completeSignup() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'address': _selectedAddress,
          'location': _selectedLocation != null
              ? GeoPoint(
                  _selectedLocation!.latitude, _selectedLocation!.longitude)
              : null, // Handle if location is not selected
          'balance': 1,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Successful!')),
        );

        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 460.0,
                    minWidth: 320.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: SizedBox(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 30.0,
                              color: Colors.teal[400],
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText('Welcome to Trashure'),
                                TypewriterAnimatedText('Create Your Account'),
                              ],
                              repeatForever: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _openAddressSelector,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Text(
                                'Select Address on Map',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _contactController,
                              decoration: InputDecoration(
                                labelText: 'Contact Number',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your contact number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Text(
                                "I already have an account",
                                style: TextStyle(color: Colors.teal[800]),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            const Divider(),
                            const Text(
                              'Terms and Conditions · Privacy Policy · CA Privacy Notice',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddressSelectionScreen extends StatefulWidget {
  final LatLng initialPosition;
  final String googleApiKey;

  const AddressSelectionScreen({
    required this.initialPosition,
    required this.googleApiKey,
    Key? key,
  }) : super(key: key);

  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  GoogleMapController? mapController;
  LatLng? selectedPosition;
  final Set<Marker> _markers = {};

  void _onMapTap(LatLng position) {
    setState(() {
      selectedPosition = position;
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('selected-position'),
        position: position,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Address on Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition,
          zoom: 14.0,
        ),
        markers: _markers,
        onTap: _onMapTap,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          if (selectedPosition != null) {
            Navigator.pop(context, selectedPosition);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a location on the map.')),
            );
          }
        },
      ),
    );
  }
}
