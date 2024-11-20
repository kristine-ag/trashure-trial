import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _filterType = 'None';
  String? _selectedDriver;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  List<String> _driverList = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
    _fetchDriverList();
  }

  // Fetch list of drivers from Firestore
  Future<void> _fetchDriverList() async {
    try {
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('position', whereIn: ['driver', 'contractual driver']).get();

      if (driversSnapshot.docs.isEmpty) {
        print('No drivers found in the employee collection.');
      }

      List<String> drivers = driversSnapshot.docs
          .map((doc) {
            if (doc.data().containsKey('name')) {
              return doc['name'] as String;
            } else {
              print('Document ${doc.id} is missing the "name" field.');
              return null;
            }
          })
          .whereType<String>()
          .toList();

      setState(() {
        _driverList = drivers;
      });

      print('Driver list fetched successfully: $_driverList');
    } catch (e) {
      print('Error fetching driver list: $e');
    }
  }

  Future<void> _fetchBookingHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      List<Map<String, dynamic>> bookingHistory = [];

      for (var bookingDoc in bookingsSnapshot.docs) {
        String bookingId = bookingDoc.id;
        Map<String, dynamic> bookingData = bookingDoc.data();

        final userDocSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId)
            .get();

        if (!userDocSnapshot.exists) continue;

        final userData = userDocSnapshot.data();
        if (userData == null ||
            !userData.containsKey('address') ||
            !userData.containsKey('contact') ||
            !userData.containsKey('status')) continue;

        final recyclablesSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId)
            .collection('recyclables')
            .get();

        List<Map<String, dynamic>> recyclables =
            recyclablesSnapshot.docs.map((doc) => doc.data()).toList();

        double finalWeight = 0.0;
        double finalItemPrice = 0.0;

        for (var recyclable in recyclables) {
          final weight = recyclable['weight'] ?? 0.0;
          final pricePerKg = recyclable['price'] ?? 0.0;

          finalWeight += weight;
          finalItemPrice += weight * pricePerKg;
        }

        bookingHistory.add({
          'date': bookingData['date'] ?? DateTime.now(),
          'bookingId': bookingId,
          'driver': bookingData['driver'] ?? 'Not yet assigned',
          'vehicle': bookingData['vehicle'] ?? 'Not yet assigned',
          'status': userData['status'] ?? 'pending',
          'recyclables': recyclables,
          'final_weight': finalWeight,
          'final_item_price': finalItemPrice,
          'final_total_weight': userData['final_total_weight'] ?? 0.0,
          'final_total_price': userData['final_total_price'] ?? 0.0,
        });
      }

      bookingHistory.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _allBookings = bookingHistory;
        _filteredBookings = bookingHistory;
      });
    } catch (e) {
      print('Error fetching booking history: $e');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = [..._allBookings];

    if (_filterType == 'Date' && _selectedDate != null) {
      filtered = filtered.where((booking) {
        final bookingDate = (booking['date'] as Timestamp).toDate();
        return bookingDate.year == _selectedDate!.year &&
            bookingDate.month == _selectedDate!.month &&
            bookingDate.day == _selectedDate!.day;
      }).toList();
    }

    if (_filterType == 'Driver' &&
        _selectedDriver != null &&
        _selectedDriver != 'All') {
      filtered = filtered
          .where((booking) => booking['driver'] == _selectedDriver)
          .toList();
    }

    setState(() {
      _filteredBookings = filtered;
    });
  }

  Widget _buildBookingTable(List<Map<String, dynamic>> bookings) {
    return Column(
      children: bookings.map((booking) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ExpansionTile(
            backgroundColor: Colors.grey[100],
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${DateFormat('MM/dd/yyyy').format((booking['date'] as Timestamp).toDate())}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Booking ID: ${booking['bookingId'] ?? 'N/A'}'),
                  Text('Driver: ${booking['driver']}'),
                  Text('Vehicle: ${booking['vehicle']}'),
                  Text(
                    'Status: ${booking['status']}',
                    style: TextStyle(
                      color: booking['status'] == 'collected'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recyclables',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...booking['recyclables'].map<Widget>((recyclable) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${recyclable['type'] ?? 'Unknown'}: ${recyclable['weight'] ?? 0} kg at ₱${recyclable['price'] ?? 0}',
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    Text(
                      'Total Weight: ${booking['final_weight']} kg',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Total Price: ₱${booking['final_item_price']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Align items to the start
        children: [
          // Date filter button
          ElevatedButton(
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  _filterType = 'Date';
                  _selectedDate = pickedDate;
                  _applyFilters();
                });
              }
            },
            child: const Text('Filter by Date'),
          ),
          const SizedBox(width: 10), // Spacing between filters
          // Driver dropdown
          DropdownButton<String>(
            value: _selectedDriver,
            hint: const Text('Filter by Driver'),
            onChanged: (value) {
              setState(() {
                _filterType = 'Driver';
                _selectedDriver = value!;
                _applyFilters();
              });
            },
            items: [
              const DropdownMenuItem(
                value: 'All',
                child: Text('Filter by Driver'),
              ),
              ..._driverList.map((driver) => DropdownMenuItem(
                    value: driver,
                    child: Text(driver),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildFilterWidget(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: _buildBookingTable(_filteredBookings),
            ),
          ),
        ],
      ),
    );
  }
}
