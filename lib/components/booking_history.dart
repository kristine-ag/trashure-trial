import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  Future<List<Map<String, dynamic>>> _getBookingHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return [];
    }

    List<Map<String, dynamic>> bookingHistory = [];

    try {
      // Fetch all documents in the bookings collection
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .get(); // No filtering at this stage

      if (bookingsSnapshot.docs.isEmpty) {
        print('No bookings found');
        return [];
      }

      for (var bookingDoc in bookingsSnapshot.docs) {
        String bookingId = bookingDoc.id;
        Map<String, dynamic> bookingData = bookingDoc.data();

        print('Processing booking ID: $bookingId');

        // Check if this booking has a user sub-collection with the current user's UID as a document ID
        final userDocSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId) // Using the current user's UID as the document ID
            .get();

        if (!userDocSnapshot.exists) {
          print(
              'No user data found for booking ID: $bookingId and user ID: $userId');
          continue; // Skip this booking if the user document doesn't exist
        }

        // Safely access the user's document data
        final userData = userDocSnapshot.data();
        if (userData == null ||
            !userData.containsKey('address') ||
            !userData.containsKey('contact') ||
            !userData.containsKey('total_price')) {
          print('Incomplete user data for booking ID: $bookingId');
          continue;
        }

        // Fetch recyclables sub-collection for this user
        final recyclablesSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId)
            .collection('recyclables')
            .get();

        List<Map<String, dynamic>> recyclables =
            recyclablesSnapshot.docs.map((doc) => doc.data()).toList();

        // Add booking details and user's data to the booking history list
        bookingHistory.add({
          'date': bookingData['date'],
          'driver': bookingData['driver'],
          'status': bookingData['status'],
          'address': userData['address'],
          'contact': userData['contact'],
          'total_price': userData['total_price'],
          'recyclables': recyclables,
        });
      }
    } catch (e) {
      print('Error fetching booking history: $e');
      return [];
    }

    return bookingHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.teal, // Sea green theme
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getBookingHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching booking history.'));
          }

          final bookingHistory = snapshot.data ?? [];
          if (bookingHistory.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(10.0), // Add padding around the grid
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                crossAxisSpacing: 10, // Spacing between cards
                mainAxisSpacing: 10, // Spacing between rows
                childAspectRatio: 0.8, // Adjust the card height/width ratio
              ),
              itemCount: bookingHistory.length,
              itemBuilder: (context, index) {
                final booking = bookingHistory[index];
                final recyclables =
                    booking['recyclables'] as List<Map<String, dynamic>>;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${booking['date'].toDate()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Driver: ${booking['driver']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Status: ${booking['status']}',
                          style: TextStyle(
                            color: booking['status'] == 'Completed'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Address: ${booking['address']}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Contact: ${booking['contact']}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Total Price: \$${booking['total_price']}',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Recyclables:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...recyclables.map((recyclable) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              '${recyclable['type']} - Weight: ${recyclable['weight']}kg, Price: \$${recyclable['item_price']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}