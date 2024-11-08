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

  Stream<List<Map<String, dynamic>>> _bookingHistoryStream() async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      yield [];
      return;
    }

    await for (var bookingsSnapshot in FirebaseFirestore.instance.collection('bookings').snapshots()) {
      List<Map<String, dynamic>> bookingHistory = [];

      if (bookingsSnapshot.docs.isEmpty) {
        yield [];
        continue;
      }

      for (var bookingDoc in bookingsSnapshot.docs) {
        String bookingId = bookingDoc.id;
        Map<String, dynamic> bookingData = bookingDoc.data();

        final userDocSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('users')
            .doc(userId)
            .get();

        if (!userDocSnapshot.exists) {
          continue;
        }

        final userData = userDocSnapshot.data();
        if (userData == null ||
            !userData.containsKey('address') ||
            !userData.containsKey('contact') ||
            !userData.containsKey('status')) {
          continue;
        }

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
        });
      }

      bookingHistory.sort((a, b) => b['date'].compareTo(a['date']));
      yield bookingHistory;
    }
  }

  Widget _buildBookingTable(List<Map<String, dynamic>> bookings, bool isDesktop) {
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
              child: isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MM/dd/yyyy').format((booking['date'] as Timestamp).toDate())),
                        Text(booking['bookingId'] ?? 'N/A'),
                        Text(booking['driver']),
                        Text(booking['vehicle']),
                        Text(
                          booking['status'],
                          style: TextStyle(
                            color: booking['status'] == 'collected' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${DateFormat('MM/dd/yyyy').format((booking['date'] as Timestamp).toDate())}',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Booking ID: ${booking['bookingId'] ?? 'N/A'}'),
                        Text('Driver: ${booking['driver']}'),
                        Text('Vehicle: ${booking['vehicle']}'),
                        Text(
                          'Status: ${booking['status']}',
                          style: TextStyle(
                            color: booking['status'] == 'collected' ? Colors.green : Colors.orange,
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
                              child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Price per kg', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                child: Text('₱${((recyclable['weight'] ?? 0) * (recyclable['price'] ?? 0)).toStringAsFixed(2)}'),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Weight: ${booking['final_weight']} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Total Price: ₱${booking['final_item_price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.teal,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _bookingHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error fetching booking history.'));
              }

              if (snapshot.hasData) {
                final bookingHistory = snapshot.data!;
                if (bookingHistory.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildBookingTable(bookingHistory, isDesktop),
                );
              } else {
                return const Center(child: Text('No bookings found.'));
              }
            },
          );
        },
      ),
    );
  }
}
