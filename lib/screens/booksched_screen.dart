import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user details
import 'package:intl/intl.dart'; // For formatting dates
import 'package:trashure/screens/bookconfirm_screen.dart';
import '../components/appbar.dart';

class BookSchedScreen extends StatefulWidget {
  const BookSchedScreen({Key? key}) : super(key: key);

  @override
  _BookSchedScreenState createState() => _BookSchedScreenState();
}

class _BookSchedScreenState extends State<BookSchedScreen> {
  String? selectedBookingId;
  String? selectedSchedule;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? selectedItems;  // To hold recyclables passed from BookingPreviewScreen
  String? address;  // To hold address passed from BookingPreviewScreen

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the arguments passed from BookingPreviewScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      selectedItems = args['selectedItems'];
      address = args['address'];
    }
  }

  // Function to fetch bookings from Firestore
  Stream<QuerySnapshot> fetchBookings() {
    return FirebaseFirestore.instance.collection('bookings').snapshots();
  }

  // Function to handle booking submission
  Future<void> submitBooking(String bookingId) async {
  try {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    final uid = user.uid;
    final email = user.email;

    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    final userRef = bookingRef.collection('users').doc(uid);
    await userRef.set({
      'uid': uid,
      'email': email,
      'address': address,
    });

    // Loop through the selected items and add each recyclable item, including the timestamp.
    if (selectedItems != null) {
      for (var entry in selectedItems!.entries) {
        await userRef.collection('recyclables').add({
          'type': entry.key,
          'quantity': entry.value['quantity'],
          'price': entry.value['price_per_kg'],
          'timestamp': (entry.value['price_timestamp'] as Timestamp).toDate(),  // Add timestamp field
        });
      }
    }

    // Show a confirmation message and navigate to BookingConfirmedScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking confirmed!')),
    );

    // Navigate to Booking Confirmed Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BookingConfirmedScreen()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('BOOKING SCHEDULE'),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 30),

            // Schedule Card from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return const Text('Error fetching bookings.');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bookings available.'));
                }

                final bookings = snapshot.data!.docs;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Schedules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Column(
                          children: bookings.map((bookingDoc) {
                            final bookingData =
                                bookingDoc.data() as Map<String, dynamic>;
                            final Timestamp dateTimestamp = bookingData['date'];
                            final DateTime bookingDate = dateTimestamp.toDate();
                            final String formattedDate =
                                DateFormat('MMMM dd, yyyy').format(bookingDate);
                            final String weekday =
                                DateFormat('EEEE').format(bookingDate);
                            final String bookingId = bookingDoc.id;

                            return _buildBookingCard(
                              context,
                              bookingId,
                              formattedDate,
                              weekday,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Book Now Button
            _buildBookNowButton(context),

            const SizedBox(height: 40),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    String date,
    String weekday,
  ) {
    final isSelected = selectedBookingId == bookingId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBookingId = bookingId;
          selectedSchedule = bookingId;
        });
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: isSelected
              ? const Color(0xFF8DD3BB)
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                Radio(
                  value: bookingId,
                  groupValue: selectedSchedule,
                  onChanged: (value) {
                    setState(() {
                      selectedSchedule = value as String?;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Book Now Button
  Widget _buildBookNowButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (selectedSchedule != null) {
            submitBooking(selectedSchedule!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select a schedule before booking.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 16, 1, 1),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterColumn('Our Scope', ['District 1', 'District 2', 'District 3']),
          _buildFooterColumn('Our Partners', ['Partner A', 'Partner B']),
          _buildFooterColumn('About Us', ['Story', 'Work with us']),
          _buildFooterColumn('Contact Us', ['Story', 'Work with us']),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
