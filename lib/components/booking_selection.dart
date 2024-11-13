import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/screens/booking_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  Map<String, dynamic> _currentBookingDetails = {};
  bool _canBook = true;
  bool _isLoading = true;
  int? _daysLeft;
  bool _showAsReceipt = false;
  String userStat = ''; // Add userStat as a state variable

  @override
  void initState() {
    super.initState();
    _checkBookingAvailability();
  }

  Future<void> _checkBookingAvailability() async {
    bool hasPendingBooking = await _checkIfUserHasPendingBooking();
    setState(() {
      _isLoading = false;
      _canBook = userStat != 'booked'; // Determine _canBook based on userStat
      _showAsReceipt = userStat == 'done'; // Show receipt if status is 'done'
    });

    // Navigate to pending or receipt screen if userStat is 'booked' or 'done'
    if (userStat == 'booked' || userStat == 'done') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _buildPendingBookingScreen(),
        ),
      );
    }
  }

  Future<bool> _checkIfUserHasPendingBooking() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) return false;

      // Update the class-level userStat variable directly
      userStat = userDoc['status'] ?? '';

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('date', descending: true)
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final userDocSnapshot =
            await bookingDoc.reference.collection('users').doc(userId).get();
        if (userDocSnapshot.exists) {
          String bookingStatus = bookingDoc['status'] ?? '';
          DateTime bookingDate = (bookingDoc['date'] as Timestamp).toDate();
          DateTime currentDate = DateTime.now();
          _daysLeft = bookingDate.difference(currentDate).inDays;
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
              'daysLeft': _daysLeft,
              'driver': bookingDoc['driver'],
              'vehicle': bookingDoc['vehicle'],
              'start_time': bookingDoc['start_time'],
              'end_time': bookingDoc['end_time'],
              'status': bookingStatus,
              'recyclables': recyclables,
              'total_weight':
                  userDocSnapshot.data()?.containsKey('total_weight') == true
                      ? userDocSnapshot['total_weight']
                      : 0.0,
              'total_price':
                  userDocSnapshot.data()?.containsKey('total_price') == true
                      ? userDocSnapshot['total_price']
                      : 0.0,
              'final_total_weight':
                  userDocSnapshot.data()?.containsKey('final_total_weight') ==
                          true
                      ? userDocSnapshot['final_total_weight']
                      : 0.0,
              'final_total_price':
                  userDocSnapshot.data()?.containsKey('final_total_price') ==
                          true
                      ? userDocSnapshot['final_total_price']
                      : 0.0,
              'calculated_total_price': userDocSnapshot
                          .data()
                          ?.containsKey('calculated_total_price') ==
                      true
                  ? userDocSnapshot['calculated_total_price']
                  : 0.0,
            };

            _showAsReceipt =
                userStat == 'done'; // Set receipt display based on status
            _canBook = userStat != 'booked';
          });

          return true;
        }
      }
    } catch (e) {
      print('Error checking pending bookings: $e');
    }
    return false;
  }

  Widget _buildPendingBookingScreen() {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showAsReceipt
                    ? 'Booking Completed!'
                    : 'You have a pending booking.',
                style: TextStyle(
                  fontSize: 30,
                  color: _showAsReceipt ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              _showAsReceipt
                  ? _buildBookingReceipt()
                  : _buildBookingDetailsTable(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingReceipt() {
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
      'final_total_weight': _currentBookingDetails['final_total_weight'] ?? 0.0,
      'final_total_price': _currentBookingDetails['final_total_price'] ?? 0.0,
      'calculated_total_price':
          _currentBookingDetails['calculated_total_price'] ?? 0.0,
    };

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                const Divider(),
                const SizedBox(height: 16),
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
                  booking['status'] == 'collected'
                      ? 'Total Weight Collected: ${booking['final_total_weight']} kg'
                      : 'Total Weight: ${booking['total_weight']} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  booking['status'] == 'collected'
                      ? 'Total Price Received: ₱${booking['final_total_price'] - 40}'
                      : 'Total Price: ₱${booking['total_price']} - 40 = ₱${booking['calculated_total_price']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await _downloadReceipt();
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'status': 'unbooked'});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: const Text(
            'Download Receipt',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadReceipt() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Booking Receipt',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${_currentBookingDetails['date'] ?? ''}'),
              pw.Text('Driver: ${_currentBookingDetails['driver'] ?? 'N/A'}'),
              pw.Text('Vehicle: ${_currentBookingDetails['vehicle'] ?? 'N/A'}'),
              pw.Text(
                  'Status: ${_currentBookingDetails['status'] ?? 'Pending'}'),
              pw.SizedBox(height: 20),
              pw.Text('Recyclables:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Type', 'Weight', 'Price per kg', 'Total'],
                data: _currentBookingDetails['recyclables']
                    .map<List<dynamic>>((recyclable) => [
                          recyclable['type'] ?? 'Unknown',
                          '${recyclable['weight'] ?? 0} kg',
                          '₱${recyclable['price'] ?? 0}',
                          '₱${((recyclable['weight'] ?? 0) * (recyclable['price'] ?? 0)).toStringAsFixed(2)}'
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Total Weight: ${_currentBookingDetails['total_weight'] ?? 0} kg'),
              pw.Text(
                  'Total Price: ₱${_currentBookingDetails['total_price'] ?? 0}'),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'booking_receipt.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "How would you like to save our planet?",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildSquareButton(
                    context: context,
                    text: 'Sell your segregated recyclable trash to trashure',
                    screen: const BookingScreen(mode: 'booking'),
                  ),
                  _buildSquareButton(
                    context: context,
                    text: 'Donate your segregated recyclable trash to trashure',
                    screen: const BookingScreen(mode: 'donate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton({
    required BuildContext context,
    required String text,
    required Widget screen,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 50),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
