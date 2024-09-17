import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user = FirebaseAuth.instance.currentUser; // Current user

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/logo.jpg'),
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/');
        },
        child: Text(
          'Trashure',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        _buildAppBarItem(context, 'Home'),
        _buildAppBarItem(context, 'Book'),
        _buildAppBarItem(context, 'Pricing'),
        if (user != null)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Error loading user data',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final userName = userData != null && userData.containsKey('name')
                  ? userData['name']
                  : 'User';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.green[700]),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      },
                    ),
                  ],
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
              ),
              child: const Row(
                children: [
                  Text('Login Now'),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // This is required to define the preferred size of the app bar
  @override
  Size get preferredSize => const Size.fromHeight(56);

  Widget _buildAppBarItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () {
          if (title == 'Home') {
            Navigator.pushNamed(context, '/');
          } else if (title == 'Book') {
            Navigator.pushNamed(context, '/Book');
          } else if (title == 'Pricing') {
            Navigator.pushNamed(context, '/Pricing');
          }
        },
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
