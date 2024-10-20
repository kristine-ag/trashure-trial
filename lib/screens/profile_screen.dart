// profile_screen.dart

// ignore_for_file: unused_field

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/booking_history.dart';
import 'package:trashure/components/firebase_options.dart';
import 'package:trashure/components/terms_and_conditions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;
  String? _profileImageUrl;
  String? _address;
  GeoPoint? _geoPoint;

  @override
  void initState() {
    super.initState();
    _getUserProfileImage();
    _getUserAddress();
  }

  Future<void> _getUserProfileImage() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['profileImage'] != null) {
        String filename = userDoc['profileImage'];
        String downloadUrl = await _storage
            .ref()
            .child('profile_images/$filename')
            .getDownloadURL();

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> _getUserAddress() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        _geoPoint = userDoc['location'] as GeoPoint;
        _address = userDoc['address'] as String;

        print(
            "GeoPoint: Latitude = ${_geoPoint?.latitude}, Longitude = ${_geoPoint?.longitude}");
        print("Address: $_address");
      }
    } catch (e) {
      print('Error fetching address: $e');
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
            _address = formattedAddress;
          });
        } else {
          print('No address found');
          _showAlertDialog('No address found.');
        }
      } else {
        print('Error fetching address');
        _showAlertDialog('Error fetching address.');
      }
    } catch (e) {
      print('Error fetching address: $e');
      _showAlertDialog('Error fetching address: $e');
    }
  }

  Future<void> _pickLocationOnMap() async {
    if (_geoPoint == null) {
      _showAlertDialog('No initial location available.');
      return;
    }

    LatLng? selectedLatLng = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          initialLocation: _geoPoint!,
        ),
      ),
    );

    if (selectedLatLng != null) {
      try {
        await _getAddressFromLatLng(selectedLatLng);

        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'location':
              GeoPoint(selectedLatLng.latitude, selectedLatLng.longitude),
          'address': _address,
        });

        setState(() {
          _geoPoint =
              GeoPoint(selectedLatLng.latitude, selectedLatLng.longitude);
        });

        _showAlertDialog('Address updated successfully!');
      } catch (e) {
        _showAlertDialog('Error fetching address: $e');
      }
    } else {
      _showAlertDialog('No location selected.');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        String filename = '$userId.jpg';
        Reference storageReference =
            _storage.ref().child('profile_images/$filename');

        SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );

        if (kIsWeb) {
          Uint8List? fileBytes = result.files.first.bytes;
          if (fileBytes != null) {
            // For web, upload the byte data
            UploadTask uploadTask =
                storageReference.putData(fileBytes, metadata);
            await uploadTask;
          }
        } else {
          // For mobile, upload the file
          File file = File(result.files.single.path!);
          UploadTask uploadTask = storageReference.putFile(file, metadata);
          await uploadTask;
        }

        // Get the download URL of the image
        String downloadUrl = await storageReference.getDownloadURL();

        // Update Firestore with the new profile image filename
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'profileImage': filename,
        });

        // Update the local state to show the new profile image
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });

        _showAlertDialog('Profile image uploaded successfully!');
      } catch (e) {
        setState(() {
          _isUploading = false;
        });

        _showAlertDialog('Failed to upload profile image: $e');
      }
    }
  }

  // New method to show AlertDialog instead of SnackBar
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data found.'));
          }

          final userDoc = snapshot.data!;
          String fullName =
              '${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}';
          String phoneNumber =
              userDoc['contact'] ?? 'No phone number available';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildProfileImageButton(),
              const SizedBox(height: 40),
              _buildPersonalInformation(fullName, phoneNumber),
              const SizedBox(height: 40),
              _buildAccountInformation(),
              const SizedBox(height: 40),
              _buildSecuritySection(),
              const SizedBox(height: 40),
              _buildSupportAndFeedback(),
              const SizedBox(height: 40),
              Divider(color: Colors.grey[400], thickness: 1, height: 1),
              _buildLogoutButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/profile_banner.png'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Center(
        child: _profileImageUrl != null
            ? CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(_profileImageUrl!),
                onBackgroundImageError: (error, stackTrace) {
                  print('Error loading image: $error');
                },
              )
            : const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
      ),
    );
  }

  Widget _buildProfileImageButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        child: _isUploading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Text('Change Profile Picture'),
      ),
    );
  }

  Widget _buildPersonalInformation(String fullName, String phoneNumber) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Full Name'),
              subtitle:
                  Text(fullName.isNotEmpty ? fullName : 'No name available'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Address'),
              subtitle: Text(_auth.currentUser!.email ?? 'No email available'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Number'),
              subtitle: Text(phoneNumber),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Address'),
              subtitle: Text(_address ?? 'No address available'),
            ),
            ElevatedButton.icon(
              onPressed: _pickLocationOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Edit Address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInformation() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookingHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View Booking/s and Transaction History'),
            ),
          ],
        ),
      ),
    );
  }

  // Updated method with password reset functionality
  Widget _buildSecuritySection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Password Reset'),
              subtitle: const Text('Tap to reset your password'),
              onTap: () async {
                final email = _auth.currentUser?.email;
                if (email == null) {
                  _showAlertDialog('No email associated with this account.');
                  return;
                }

                final shouldReset = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Password'),
                    content: Text(
                        'We will send a password reset email to $email. Do you want to proceed?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                );

                if (shouldReset == true) {
                  try {
                    await _auth.sendPasswordResetEmail(email: email);
                    _showAlertDialog('Password reset email sent to $email');
                  } catch (e) {
                    _showAlertDialog('Error sending password reset email: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportAndFeedback() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support & Feedback',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              subtitle: const Text('Tap to provide feedback'),
              onTap: () {
                // Add feedback logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms & Conditions / Privacy Policy'),
              subtitle: const Text('Tap to view'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermsAndConditionsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Sign out the user from Firebase
            await _auth.signOut();

            // Navigate to the Home Screen (replace 'HomeScreen' with the actual route or widget)
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/', // Assuming '/home' is the route name for your HomeScreen
              (Route<dynamic> route) => false, // Removes all previous routes
            );
          } catch (e) {
            _showAlertDialog('Error logging out: $e');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final GeoPoint initialLocation;

  const MapScreen({Key? key, required this.initialLocation}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLatLng;
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLatLng != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(
                    context, _selectedLatLng); // Return the selected location
              },
            )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.initialLocation.latitude,
              widget.initialLocation.longitude),
          zoom: 16,
        ),
        onMapCreated: (controller) => _mapController = controller,
        onTap: (latLng) {
          // Update the selectedLatLng when the user taps on the map
          setState(() {
            _selectedLatLng = latLng;
          });
        },
        markers: _selectedLatLng != null
            ? {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: _selectedLatLng!,
                )
              }
            : {},
      ),
    );
  }
}
