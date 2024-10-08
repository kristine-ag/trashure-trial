import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

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
            .doc(userId)
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

      // Sort the bookingHistory list based on the date in descending order
      bookingHistory.sort((a, b) => b['date'].compareTo(a['date']));
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
        title: const Text('Booking/s and Transaction History'),
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
            padding:
                const EdgeInsets.all(8.0), // Reduced padding around the grid
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300, // Max width per card
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: bookingHistory.length,
              itemBuilder: (context, index) {
                final booking = bookingHistory[index];
                final recyclables =
                    booking['recyclables'] as List<Map<String, dynamic>>;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // Hug content vertically
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${DateFormat.yMMMd().format(booking['date'].toDate())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Driver: ${booking['driver']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Status: ${booking['status']}',
                          style: TextStyle(
                            color: booking['status'] == 'Completed'
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Address: ${booking['address']}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Contact: ${booking['contact']}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Total Price: \$${booking['total_price']}',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Recyclables:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Wrap recyclables in Flexible to prevent overflow
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true, // Take only needed space
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recyclables.length,
                            itemBuilder: (context, i) {
                              final recyclable = recyclables[i];
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '${recyclable['type']} - ${recyclable['weight']}kg, \$${recyclable['item_price']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
