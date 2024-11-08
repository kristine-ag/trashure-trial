import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user = FirebaseAuth.instance.currentUser; // Current user

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the screen width is larger than a typical mobile screen
        bool isDesktop = constraints.maxWidth > 600;

        return AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/logo.png'),
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
                fontSize: isDesktop ? 30 : 24,
              ),
            ),
          ),
          actions: isDesktop
              ? _buildDesktopActions(context) // Show all items if desktop
              : _buildMobileActions(context), // Use Drawer or PopupMenu if mobile
        );
      },
    );
  }

  // Desktop Actions: All items visible in the AppBar
  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      _buildAppBarItem(context, 'Home'),
      _buildAppBarItem(context, 'Book'),
      _buildAppBarItem(context, 'Pricing'),
      if (user != null)
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
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
            final userName = userData != null && userData.containsKey('firstName')
                ? userData['firstName']
                : 'User';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/Profile'); // Navigate to Profile Screen
                    },
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    ];
  }

  // Mobile Actions: Popup menu or Drawer for small screens
  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      if (user != null) _buildUserName(context),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'Home') {
            Navigator.pushNamed(context, '/');
          } else if (value == 'Book') {
            Navigator.pushNamed(context, '/Book');
          } else if (value == 'Pricing') {
            Navigator.pushNamed(context, '/Pricing');
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'Home',
            child: Text('Home'),
          ),
          const PopupMenuItem(
            value: 'Book',
            child: Text('Book'),
          ),
          const PopupMenuItem(
            value: 'Pricing',
            child: Text('Pricing'),
          ),
        ],
      ),
    ];
  }

  // Function to build the username widget in the app bar
  Widget _buildUserName(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
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
        final userName = userData != null && userData.containsKey('firstName')
            ? userData['firstName']
            : 'User';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/Profile');
            },
            child: Text(
              userName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // This is required to define the preferred size of the app bar
  @override
  Size get preferredSize => const Size.fromHeight(60);

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
