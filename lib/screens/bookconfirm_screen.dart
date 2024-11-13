import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/footer.dart';
import 'package:intl/intl.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;
  const BookingConfirmedScreen({super.key, required this.bookingDetails});

  @override
  _BookingConfirmedScreenState createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  Map<String, dynamic> _currentBookingDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      for (var bookingDoc in bookingsSnapshot.docs) {
        final userDocSnapshot =
            await bookingDoc.reference.collection('users').doc(userId).get();
        if (userDocSnapshot.exists) {
          String userStatus = userDocSnapshot['status'] ?? '';
          if (userStatus == 'booked') {
            Timestamp bookingDateTimestamp = bookingDoc['date'];
            DateTime bookingDate = bookingDateTimestamp.toDate();
            List<Map<String, dynamic>> recyclables = [];

            final recyclablesSnapshot =
              await userDocSnapshot.reference.collection('recyclables').get();
          for (var recyclableDoc in recyclablesSnapshot.docs) {
            double weight = recyclableDoc.data()['weight'] ?? 0.0;
            double price = recyclableDoc.data()['item_price'] ?? 0.0;
            recyclables.add({
              'type': recyclableDoc.data()['type'] ?? 'Unknown',
              'price': recyclableDoc.data()['price'] ?? 0,
              'item_price': price,
              'quantity': recyclableDoc.data()['quantity'] ?? 0,
              'weight': weight,
            });
          }

            setState(() {
              _currentBookingDetails = {
                'date': bookingDate,
                'driver': bookingDoc['driver'],
                'vehicle': bookingDoc['vehicle'],
                'start_time': bookingDoc['start_time'],
                'end_time': bookingDoc['end_time'],
                'status': bookingDoc['status'],
                'recyclables': recyclables,
                'total_weight': userDocSnapshot['total_weight'] ?? 0.0,
                'total_price': userDocSnapshot['total_price'] ?? 0.0,
                'calculated_total_price':
                    userDocSnapshot['calculated_total_price'] ?? 0.0,
              };
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error fetching booking details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              'BOOKING CONFIRMED',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 4,
              width: 350,
              color: Colors.green[700],
            ),
            const SizedBox(height: 60),
            const Icon(
              Icons.check_circle,
              size: 150,
              color: Colors.green,
            ),
            const SizedBox(height: 40),
            _buildBookingDetailsTable(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'RETURN HOME',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 80),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsTable() {
    final bookingDate = _currentBookingDetails['date'];
    final formattedBookingDate = bookingDate is DateTime
        ? DateFormat('MM/dd/yyyy').format(bookingDate)
        : 'N/A';

    final booking = {
      'date': formattedBookingDate,
      'driver': _currentBookingDetails['driver'] ?? 'Not Yet Assigned',
      'vehicle': _currentBookingDetails['vehicle'] ?? 'Not Yet Assigned',
      'status': _currentBookingDetails['status'] ?? 'booked',
      'recyclables': _currentBookingDetails['recyclables'] ?? [],
      'total_weight': _currentBookingDetails['total_weight'] ?? 0.0,
      'total_price': _currentBookingDetails['total_price'] ?? 0.0,
      'calculated_total_price':
          _currentBookingDetails['calculated_total_price'] ?? 0.0,
    };

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
                'Date: $formattedBookingDate',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(color: Colors.grey, width: 0.5),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Type',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Weight',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Price per kg',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...booking['recyclables'].map<TableRow>((recyclable) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(recyclable['type'] ?? 'Unknown'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${recyclable['weight'] ?? 0} kg'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('₱${recyclable['price'] ?? 0}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                '₱${((recyclable['item_price'] ?? 0)).toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Weight: ${booking['total_weight']} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Total Price: ₱${booking['total_price']} - 40 = ₱${booking['calculated_total_price']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
