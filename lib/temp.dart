import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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

        // Fetch the customer review
        final customerReviewSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId)
            .collection('customer_review')
            .get();

        List<Map<String, dynamic>> reviews =
            customerReviewSnapshot.docs.map((doc) => doc.data()).toList();

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
          'reviews': reviews,
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final date = (booking['date'] as Timestamp).toDate();
        final recyclables =
            booking['recyclables'] as List<Map<String, dynamic>>;
        final reviews = booking['reviews'] as List<Map<String, dynamic>>;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${DateFormat('MM/dd/yyyy').format(date)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Booking ID: ${booking['bookingId'] ?? 'N/A'}'),
                      Text('Driver: ${booking['driver']}'),
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                        },
                        border: TableBorder.all(color: Colors.grey),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Weight (kg)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Price (₱)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          ...recyclables.map((item) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(item['type'] ?? 'Unknown'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${item['weight'] ?? 0}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('₱${item['price'] ?? 0}'),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment:
                            Alignment.centerLeft, // Align content to the left
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Ensure left alignment for the column's children
                          children: [
                            Text(
                              'Total Weight: ${booking['final_weight']?.toStringAsFixed(2) ?? '0.00'} kg',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Total Price: ₱${booking['final_item_price']?.toStringAsFixed(2) ?? '0.00'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Reviews',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...reviews.map((review) {
                        final reviewDate =
                            (review['date'] as Timestamp).toDate();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingBarIndicator(
                              rating: review['rating'] ?? 0.0,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                            ),
                            Text('Feedback: ${review['feedback'] ?? 'N/A'}'),
                            Text(
                              'Date: ${DateFormat('MM/dd/yyyy').format(reviewDate)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
