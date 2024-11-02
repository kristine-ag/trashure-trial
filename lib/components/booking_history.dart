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

  Stream<List<Map<String, dynamic>>> _bookingHistoryStream() async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      yield [];
      return;
    }

    // Listen to snapshots of the bookings collection
    await for (var bookingsSnapshot
        in FirebaseFirestore.instance.collection('bookings').snapshots()) {
      List<Map<String, dynamic>> bookingHistory = [];

      if (bookingsSnapshot.docs.isEmpty) {
        print('No bookings found');
        yield [];
        continue;
      }

      // Process each booking document
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
            !userData.containsKey('final_total_price') ||
            !userData.containsKey('status')) {
          // Check for the user-specific status
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
          'status': userData['status'], // Use user-specific status
          'address': userData['address'],
          'contact': userData['contact'],
          'final_total_price': userData['final_total_price'], // Fetch final_total_price
          'recyclables': recyclables,
          'final_weight': finalWeight,
          'final_item_price': finalItemPrice,
        });
      }

      // Sort the bookingHistory list based on the date in descending order
      bookingHistory.sort((a, b) => b['date'].compareTo(a['date']));

      yield bookingHistory;
    }
  }

  // Apply filters to the collected bookings
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> collectedBookings) {
    List<Map<String, dynamic>> filteredBookings = collectedBookings;

    if (_filterType == 'Driver' && _selectedDriver != null) {
      filteredBookings = filteredBookings
          .where((booking) => booking['driver'] == _selectedDriver)
          .toList();
    } else if (_filterType == 'Date' && _selectedDate != null) {
      filteredBookings = filteredBookings.where((booking) {
        final bookingDate = booking['date'].toDate();
        return bookingDate.year == _selectedDate!.year &&
            bookingDate.month == _selectedDate!.month &&
            bookingDate.day == _selectedDate!.day;
      }).toList();
    }

    return filteredBookings;
  }

  // Build filter options UI
  Widget _buildFilterOptions(List<Map<String, dynamic>> collectedBookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Collected Bookings By:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _filterType,
                isExpanded: true,
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
            const SizedBox(width: 8),
            if (_filterType == 'Driver')
              Expanded(child: _buildDriverDropdown(collectedBookings)),
            if (_filterType == 'Date') Expanded(child: _buildDatePicker()),
          ],
        ),
      ],
    );
  }

  // Build driver dropdown for filtering
  Widget _buildDriverDropdown(List<Map<String, dynamic>> collectedBookings) {
    final drivers = collectedBookings
        .map((booking) => booking['driver'] as String)
        .toSet()
        .toList();

    return DropdownButton<String>(
      hint: const Text('Select Driver'),
      value: _selectedDriver,
      isExpanded: true,
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
    );
  }

  // Date picker for filtering
  Widget _buildDatePicker() {
    return InkWell(
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
    );
  }

  Widget _buildBookingRows(List<Map<String, dynamic>> bookings) {
    List<Widget> rows = [];

    for (int i = 0; i < bookings.length; i += 2) {
      if (i + 1 < bookings.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: _buildBookingCard(bookings[i])),
              const SizedBox(width: 10), // Space between the two cards
              Expanded(child: _buildBookingCard(bookings[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(
          Row(
            children: [
              Expanded(child: _buildBookingCard(bookings[i])),
            ],
          ),
        );
      }
      rows.add(const SizedBox(height: 10)); // Add spacing between rows
    }

    return Column(children: rows);
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final recyclables = booking['recyclables'] as List<Map<String, dynamic>>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0), // Adjust margin
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
              'Status: ${booking['status']}', // Show user-specific status
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
            // Use final_total_price instead of total_price
            Text(
              'Total Price: \₱${booking['final_total_price']}',
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recyclables.length,
              itemBuilder: (context, i) {
                final recyclable = recyclables[i];

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${recyclable['type']} - ${recyclable['weight']}kg, \₱${recyclable['item_price']}',
                        ),
                        // Display 'final_weight' and 'final_item_price' from the database in green
                        TextSpan(
                          text:
                              '\nTotal Weight: ${recyclable['final_weight']}kg, Total Price: \₱${recyclable['final_item_price']}',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking/s and Transaction History'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _bookingHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Display a loading indicator while waiting for data
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Display an error message if there is an error
            return const Center(child: Text('Error fetching booking history.'));
          }

          if (snapshot.hasData) {
            final bookingHistory = snapshot.data!;
            if (bookingHistory.isEmpty) {
              return const Center(child: Text('No bookings found.'));
            }

            // Separate bookings based on user-specific status
            final collectedBookings = bookingHistory
                .where((booking) => booking['status'] == 'collected')
                .toList();
            final ongoingBookings = bookingHistory
                .where((booking) => booking['status'] != 'collected')
                .toList();

            // Apply filters to collected bookings
            List<Map<String, dynamic>> filteredCollectedBookings =
                _applyFilters(collectedBookings);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (ongoingBookings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ongoing Bookings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBookingRows(ongoingBookings),
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
                    // Filter options under Collected Bookings
                    _buildFilterOptions(collectedBookings),
                    const SizedBox(height: 8),
                    if (filteredCollectedBookings.isNotEmpty)
                      _buildBookingRows(filteredCollectedBookings)
                    else
                      const Center(
                        child: Text('No bookings match the selected filter.'),
                      ),
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
