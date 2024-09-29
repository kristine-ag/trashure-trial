import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:trashure/components/appbar.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserProfileImage();
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
        Reference storageReference = _storage.ref().child('profile_images/$filename');

        SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );

        if (kIsWeb) {
          Uint8List? fileBytes = result.files.first.bytes;
          if (fileBytes != null) {
            // For web, upload the byte data
            UploadTask uploadTask = storageReference.putData(fileBytes, metadata);
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
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profileImage': filename,
        });

        // Update the local state to show the new profile image
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image uploaded successfully!')),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile image: $e')),
        );
      }
    }
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
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data found.'));
          }

          final userDoc = snapshot.data!;
          String fullName = '${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}';
          String phoneNumber = userDoc['contact'] ?? 'No phone number available';
          int balance = userDoc['balance'] ?? 0;
          // List bookingHistory = userDoc['bookingHistory'] ?? [];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildProfileImageButton(), // New button to change profile image
              const SizedBox(height: 40),
              _buildPersonalInformation(fullName, phoneNumber),
              const SizedBox(height: 40),
              _buildAccountInformation(balance),
              const SizedBox(height: 40),
              // _buildBookingInformation(bookingHistory),
              // const SizedBox(height: 40),
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
                backgroundImage: NetworkImage(_profileImageUrl!),
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
              subtitle: Text(fullName.isNotEmpty ? fullName : 'No name available'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInformation(int balance) {
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
            ListTile(
              leading: const Icon(Icons.stars),
              title: const Text('Points/Rewards Balance'),
              subtitle: Text('$balance points'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBookingInformation(List bookingHistory) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     elevation: 3,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Booking Information',
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 20,
  //             ),
  //           ),
  //           const SizedBox(height: 10),
  //           bookingHistory.isNotEmpty
  //               ? Column(
  //                   children: bookingHistory.map((booking) {
  //                     return ListTile(
  //                       leading: const Icon(Icons.history),
  //                       title: Text('Booking at ${booking['venue']}'),
  //                       subtitle: Text(
  //                           'Date: ${booking['date']}\nStatus: ${booking['status']}'),
  //                     );
  //                   }).toList(),
  //                 )
  //               : const Text('No bookings available.'),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
              onTap: () {
                // Add password reset logic here
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
                // Add Terms & Conditions or Privacy Policy navigation logic here
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
        onPressed: () {
          _auth.signOut();
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
