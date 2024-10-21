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

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getBookingHistory().catchError((error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching booking history.';
      });
    });
  }

  Future<void> _getBookingHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      setState(() {
        _errorMessage = 'No user logged in';
        _isLoading = false;
      });
      return;
    }

    List<Map<String, dynamic>> bookingHistory = [];

    try {
      // Fetch all documents in the bookings collection
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .get(); // No filtering at this stage

      if (bookingsSnapshot.docs.isEmpty) {
        print('No bookings found');
        setState(() {
          _errorMessage = 'No bookings found';
          _isLoading = false;
        });
        return;
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
      setState(() {
        collectedBookings = bookingHistory
            .where((booking) => booking['status'] == 'collected')
            .toList();
        otherBookings = bookingHistory
            .where((booking) => booking['status'] != 'collected')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching booking history: $e');
      setState(() {
        _errorMessage = 'Error fetching booking history.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyFilters() {
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

  Widget _buildFilterOptions() {
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
            if (_filterType == 'Driver') Expanded(child: _buildDriverDropdown()),
            if (_filterType == 'Date') Expanded(child: _buildDatePicker()),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverDropdown() {
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

  Widget _buildBookingGrid(List<Map<String, dynamic>> bookings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final recyclables =
                booking['recyclables'] as List<Map<String, dynamic>>;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: SingleChildScrollView(
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
                        shrinkWrap: true,
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking/s and Transaction History'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking/s and Transaction History'),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // Apply filters
    List<Map<String, dynamic>> filteredCollectedBookings = _applyFilters();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking/s and Transaction History'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (otherBookings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current Bookings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildBookingGrid(otherBookings),
            ],
            if (collectedBookings.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Collected Bookings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Filter options under Collected Bookings
              _buildFilterOptions(),
              const SizedBox(height: 8),
              if (filteredCollectedBookings.isNotEmpty)
                _buildBookingGrid(filteredCollectedBookings)
              else
                const Center(
                  child: Text('No bookings match the selected filter.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
