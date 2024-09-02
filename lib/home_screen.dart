import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.jpg'), 
        ),
        title: Text(
          'Trashure',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          _buildAppBarItem(context, 'Home'),
          _buildAppBarItem(context, 'Book'),
          _buildAppBarItem(context, 'Pricing'),
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.photoURL ?? 'https://via.placeholder.com/150'),
                      ),
                      SizedBox(width: 8),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.green[700]),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                child: Row(
                  children: [
                    Text('Login Now'),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBanner(context),
            SizedBox(height: 20),
            _buildGoalSection(context),
            SizedBox(height: 40),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/$title');
        },
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
  return Card(
    margin: const EdgeInsets.all(50.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0), 
    ),
    clipBehavior: Clip.antiAlias, 
    elevation: 5.0, 
    child: Stack(
      children: [
        Image.asset(
          'assets/images/banner.jpg',
          width: double.infinity,
          height: 500,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Text(
            'TURN YOUR PLASTIC WASTE INTO TREASURE WITH TRASHURE!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black,
                  offset: Offset(5.0, 5.0),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildGoalSection(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 64.0), 
    child: Column(
      children: [
        Text(
          'HELP US REACH',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'OUR GOAL!',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'OUR MONTHLY GOAL',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              _buildProgressBar(1000.0, 800.0, 'Mar'),
              _buildProgressBar(1000.0, 700.0, 'Feb'),
              _buildProgressBar(1000.0, 1000.0, 'Jan'),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildProgressBar(double goal, double progress, String month) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress / goal,
          backgroundColor: Colors.green[100],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterColumn('Our Scope', ['Sample District 1', 'Sample District 2', 'Sample District 3']),
          _buildFooterColumn('Our Partners', ['Lalala Inc.', 'Trash R Us', 'SM Cares']),
          _buildFooterColumn('About Us', ['Our Story', 'Work with us']),
          _buildFooterColumn('Contact Us', ['Our Story', 'Work with us']),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              item,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
