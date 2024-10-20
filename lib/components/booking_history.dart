import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _filterType = 'None'; // Options: 'None', 'Driver', 'Date'
  String? _selectedDriver;
  DateTime? _selectedDate;

  List<Map<String, dynamic>> collectedBookings = [];
  List<Map<String, dynamic>> otherBookings = [];

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

        // Calculate final_weight and final_item_price
        double finalWeight = 0.0;
        double finalItemPrice = 0.0;

        for (var recyclable in recyclables) {
          final weight = recyclable['weight'] ?? 0.0;
          final itemPrice = recyclable['item_price'] ?? 0.0;

          finalWeight += weight;
          finalItemPrice += itemPrice;
        }

        // Add booking details and user's data to the booking history list
        bookingHistory.add({
          'date': bookingData['date'],
          'driver': bookingData['driver'],
          'status': bookingData['status'],
          'address': userData['address'],
          'contact': userData['contact'],
          'total_price': userData['total_price'],
          'recyclables': recyclables,
          'final_weight': finalWeight,
          'final_item_price': finalItemPrice,
        });
      }

      // Sort the bookingHistory list based on the date in descending order
      bookingHistory.sort((a, b) => b['date'].compareTo(a['date']));

      // Separate bookings with 'collected' status
      collectedBookings = bookingHistory
          .where((booking) => booking['status'] == 'collected')
          .toList();
      otherBookings = bookingHistory
          .where((booking) => booking['status'] != 'collected')
          .toList();
    } catch (e) {
      print('Error fetching booking history: $e');
      return [];
    }

    return bookingHistory;
  }

  Widget _buildFilterOptions() {
    // Get the list of unique drivers from collectedBookings
    final drivers = collectedBookings
        .map((booking) => booking['driver'] as String)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter By:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _filterType,
                items: ['None', 'Driver', 'Date'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newFilter) {
                  setState(() {
                    _filterType = newFilter!;
                    _selectedDriver = null;
                    _selectedDate = null;
                  });
                },
              ),
            ),
            if (_filterType == 'Driver')
              Expanded(
                child: DropdownButton<String>(
                  hint: const Text('Select Driver'),
                  value: _selectedDriver,
                  items: drivers.map((String driver) {
                    return DropdownMenuItem<String>(
                      value: driver,
                      child: Text(driver),
                    );
                  }).toList(),
                  onChanged: (newDriver) {
                    setState(() {
                      _selectedDriver = newDriver;
                    });
                  },
                ),
              ),
            if (_filterType == 'Date')
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Text(_selectedDate == null
                          ? 'Select Date'
                          : DateFormat.yMMMd().format(_selectedDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final recyclables =
            booking['recyclables'] as List<Map<String, dynamic>>;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${DateFormat.yMMMd().format(booking['date'].toDate())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Driver: ${booking['driver']}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Status: ${booking['status']}',
                  style: TextStyle(
                    color: booking['status'] == 'collected'
                        ? Colors.green
                        : Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${booking['address']}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Contact: ${booking['contact']}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total Price: \$${booking['total_price']}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recyclables:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ListView.builder(
                  shrinkWrap: true, // Take only needed space
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recyclables.length,
                  itemBuilder: (context, i) {
                    final recyclable = recyclables[i];

                    return Padding(
                      padding:
                          const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${recyclable['type']} - ${recyclable['weight']}kg, \$${recyclable['item_price']}',
                            ),
                            if (booking['status'] == 'collected')
                              TextSpan(
                                text:
                                    '\nTotal Weight: ${booking['final_weight']}kg, Total Price: \₱${booking['final_item_price']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenWidth = MediaQuery.of(context).size.width;

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
            return const Center(
                child: Text('Error fetching booking history.'));
          }

          if (snapshot.hasData) {
            // Apply filters
            List<Map<String, dynamic>> filteredCollectedBookings =
                collectedBookings;

            if (_filterType == 'Driver' && _selectedDriver != null) {
              filteredCollectedBookings = collectedBookings
                  .where((booking) => booking['driver'] == _selectedDriver)
                  .toList();
            } else if (_filterType == 'Date' && _selectedDate != null) {
              filteredCollectedBookings = collectedBookings.where((booking) {
                final bookingDate = booking['date'].toDate();
                return bookingDate.year == _selectedDate!.year &&
                    bookingDate.month == _selectedDate!.month &&
                    bookingDate.day == _selectedDate!.day;
              }).toList();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (otherBookings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Other Bookings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBookingList(otherBookings),
                  ],
                  if (collectedBookings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Collected Bookings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Filter options
                    _buildFilterOptions(),
                    const SizedBox(height: 8),
                    _buildBookingList(filteredCollectedBookings),
                  ],
                ],
              ),
            );
          } else {
            return const Center(child: Text('No bookings found.'));
          }
        },
      ),
    );
  }
}
