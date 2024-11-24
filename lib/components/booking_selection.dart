// ignore_for_file: unused_field, unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/screens/booking_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'dart:html' as html;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import 'package:trashure/screens/home_screen.dart';

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
  String userStat = '';
  String userCat = '';
  String userReview = '';

  @override
  void initState() {
    super.initState();
    _checkBookingAvailability();
  }

  Future<void> _checkBookingAvailability() async {
    await _checkIfUserHasPendingBooking();
    setState(() {
      _isLoading = false;
      _canBook = userStat != 'booked';
      _showAsReceipt = userStat == 'done';
    });

    if (userStat == 'done' || userStat == 'booked') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _buildPendingBookingScreen(),
        ),
      );
    }
  }

  Future<void> _showRatingModal() async {
    double rating = 0;
    TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate Your Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'How was your TRASHURE experience?',
                  hintText: 'Let us know so we can serve you better!',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitReview(rating, feedbackController.text);
                Navigator.of(context).pop();
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'review': 'rated'});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReview(double rating, String feedback) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        // Fetch user details
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final firstName = userDoc['firstName'] ?? 'Anonymous';
        final lastName = userDoc['lastName'] ?? '';
        final userName = '$firstName $lastName';

        // Fetch the user's active booking ID
        String? bookingId;
        final bookingsSnapshot =
            await FirebaseFirestore.instance.collection('bookings').get();

        for (var bookingDoc in bookingsSnapshot.docs) {
          final userBookingDoc =
              await bookingDoc.reference.collection('users').doc(userId).get();

          if (userBookingDoc.exists) {
            bookingId = bookingDoc.id; // Set the booking ID
            break; // Assuming the user can only have one active booking at a time
          }
        }

        // If booking ID is found, include it in the review
        final reviewData = {
          'user_id': userId,
          'name': userName,
          'rating': rating,
          'feedback': feedback,
          'date': Timestamp.now(),
        };

        if (bookingId != null) {
          reviewData['booking_id'] = bookingId;
        }

        // Add the review to the `customer_review` collection
        await FirebaseFirestore.instance
            .collection('customer_review')
            .add(reviewData);

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .collection('customer_review')
            .add(reviewData);

        // Update the user's review status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'review': 'rated'});

        Fluttertoast.showToast(
          msg: 'Thank you for your feedback!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error submitting review: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
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
      userCat = userDoc['category'] ?? '';
      userStat = userDoc['status'] ?? '';
      userReview = userDoc['review'] ?? '';

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('date', descending: true)
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final userDocSnapshot =
            await bookingDoc.reference.collection('users').doc(userId).get();
        if (userDocSnapshot.exists) {
          // String bookingStatus = bookingDoc['status'] ?? '';
          DateTime bookingDate = (bookingDoc['date'] as Timestamp).toDate();
          DateTime currentDate = DateTime.now();
          _daysLeft = bookingDate.difference(currentDate).inDays;
          List<Map<String, dynamic>> recyclables = [];

          String mode = userDocSnapshot.data()?['mode'] ?? 'booking';

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
              'final_item_price': recyclableDoc.data()['final_item_price'] ?? 0,
              'final_weight': recyclableDoc.data()['final_weight'] ?? 0,
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
              'status': userDocSnapshot['status'],
              'category': userDocSnapshot['category'],
              'recyclables': recyclables,
              'mode': mode,
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
            print(userDocSnapshot['status']);

            _showAsReceipt = userStat == 'done';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userStat == 'done' && userReview == 'unrated') {
        _showRatingModal();
      }
    });

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAsReceipt
                        ? 'Booking Completed!'
                        : 'You have a pending booking.',
                    style: TextStyle(
                      fontSize: 30,
                      color: _showAsReceipt ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
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
      'mode': _currentBookingDetails['mode'] ?? 'unknown',
      'driver': _currentBookingDetails['driver'] ?? 'Not Yet Assigned',
      'vehicle': _currentBookingDetails['vehicle'] ?? 'Not Yet Assigned',
      'status': _currentBookingDetails['status'] ?? 'booked',
      'category': _currentBookingDetails['category'] ?? '',
      'recyclables': _currentBookingDetails['recyclables'] ?? [],
      'total_weight': _currentBookingDetails['total_weight'] ?? 0.0,
      'total_price': _currentBookingDetails['total_price'] ?? 0.0,
      'final_total_weight': _currentBookingDetails['final_total_weight'] ?? 0.0,
      'final_total_price': _currentBookingDetails['final_total_price'] ?? 0.0,
      'calculated_total_price':
          _currentBookingDetails['calculated_total_price'] ?? 0.0,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    isMobile
                        ? _buildRecyclablesAsList(booking['recyclables'])
                        : _buildRecyclablesAsTable(booking['recyclables']),
                    const SizedBox(height: 12),
                    Text(
                      booking['status'] == 'collected'
                          ? 'Total Weight Collected: ${booking['final_total_weight']} kg'
                          : 'Total Weight: ${booking['total_weight']} kg',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      booking['mode'] == 'donate'
                          ? (_currentBookingDetails['status'] == 'collected'
                              ? 'Total Price Received: ₱0'
                              : 'Total Price: ₱0')
                          : (_currentBookingDetails['category'] == 'business'
                              ? (_currentBookingDetails['status'] == 'collected'
                                  ? 'Total Price Received: ₱${_currentBookingDetails['final_total_price']}'
                                  : 'Total Price: ₱${_currentBookingDetails['total_price']}')
                              : (_currentBookingDetails['status'] == 'collected'
                                  ? 'Total Price Received: ₱${_currentBookingDetails['final_total_price'] - 40}'
                                  : 'Total Price: ₱${_currentBookingDetails['total_price']} - 40 = ₱${_currentBookingDetails['calculated_total_price']}')),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            isMobile
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _buildActionButtons(),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildActionButtons(spaced: true),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildRecyclablesAsTable(List<Map<String, dynamic>> recyclables) {
    return Table(
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
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Price per kg',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...recyclables.map<TableRow>((recyclable) {
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
    );
  }

  Widget _buildRecyclablesAsList(List<Map<String, dynamic>> recyclables) {
    return Column(
      children: recyclables.map((recyclable) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${recyclable['type'] ?? 'Unknown'}'),
                Text('Weight: ${recyclable['weight'] ?? 0} kg'),
                Text('Price per kg: ₱${recyclable['price'] ?? 0}'),
                Text(
                  'Total: ₱${((recyclable['item_price'] ?? 0)).toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildActionButtons({bool spaced = false}) {
    return [
      ElevatedButton(
        onPressed: () async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'status': 'unbooked'});
          }

          Navigator.pushNamed(context, '/');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
        child: const Text(
          'Go to Home',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      const SizedBox(width: 20, height: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
        child: const Text(
          'Download Receipt',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      const SizedBox(width: 20, height: 20),
      ElevatedButton(
        onPressed: () async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'status': 'unbooked'});
          }

          Navigator.pushNamed(context, '/Book');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
        child: const Text(
          'Book Again',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    ];
  }

  Future<void> _downloadReceipt() async {
    try {
      final pdf = pw.Document();

      // Load the logo image as bytes
      final ByteData logoBytes =
          await rootBundle.load('assets/images/logo.png');
      final Uint8List logoImage = logoBytes.buffer.asUint8List();

      // Extract booking details
      final bookingDate = _currentBookingDetails['date'];
      final formattedBookingDate = bookingDate is DateTime
          ? DateFormat('MM/dd/yyyy').format(bookingDate)
          : 'N/A';

      final booking = {
        'driver': _currentBookingDetails['driver'] ?? 'Not Yet Assigned',
        'vehicle': _currentBookingDetails['vehicle'] ?? 'Not Yet Assigned',
        'status': _currentBookingDetails['status'] ?? 'booked',
        'recyclables': _currentBookingDetails['recyclables'] ?? [],
        'total_weight': _currentBookingDetails['total_weight'] ?? 0.0,
        'final_total_weight':
            _currentBookingDetails['final_total_weight'] ?? 0.0,
        'total_price': _currentBookingDetails['total_price'] ?? 0.0,
        'final_total_price': _currentBookingDetails['final_total_price'] ?? 0.0,
        'calculated_total_price':
            _currentBookingDetails['calculated_total_price'] ?? 0.0,
        'mode': _currentBookingDetails['mode'] ?? 'unknown',
        'category': _currentBookingDetails['category'] ?? '',
      };

      // Create the PDF content
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo and Title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Trashure Booking Receipt',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Image(
                      pw.MemoryImage(logoImage),
                      height: 50,
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Booking Details
                pw.Text(
                  'Booking Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Date: $formattedBookingDate'),
                pw.Text('Driver: ${booking['driver']}'),
                pw.Text('Vehicle: ${booking['vehicle']}'),
                pw.Text(
                  'Status: ${booking['status']}',
                  style: pw.TextStyle(
                    color: booking['status'] == 'collected'
                        ? PdfColors.green
                        : PdfColors.orange,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Recyclables Table
                pw.Text(
                  'Recyclables',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: [
                    'Type',
                    'Weight (kg)',
                    if (booking['status'] == 'collected') 'Final Weight (kg)',
                    'Price per kg',
                    'Item Price',
                    if (booking['status'] == 'collected') 'Final Item Price',
                  ],
                  data: booking['recyclables'].map<List<dynamic>>((recyclable) {
                    return [
                      recyclable['type'] ?? 'Unknown',
                      '${recyclable['weight'] ?? 0} kg',
                      if (booking['status'] == 'collected')
                        '${recyclable['final_weight'] ?? 0} kg',
                      'PHP${recyclable['price'] ?? 0}',
                      'PHP${(recyclable['item_price'] ?? 0).toStringAsFixed(2)}',
                      if (booking['status'] == 'collected')
                        'PHP${(recyclable['final_item_price'] ?? 0).toStringAsFixed(2)}',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // Summary
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Weight: ${booking['total_weight']} kg',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  booking['mode'] == 'donate'
                      ? 'Total Price: PHP0'
                      : booking['category'] == 'business'
                          ? 'Total Price: PHP ${booking['total_price']}'
                          : 'Total Price: PHP ${booking['total_price']} - 40 = PHP${booking['calculated_total_price']}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF
      final Uint8List pdfBytes = await pdf.save();

      // Trigger download with an anchor element
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'Trashure_Booking_Receipt.pdf'
        ..click();
      html.Url.revokeObjectUrl(url);

      // Show success toast
      Fluttertoast.showToast(
        msg: 'Receipt downloaded successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      // Show error toast
      Fluttertoast.showToast(
        msg: 'Error downloading receipt: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildBookingDetailsTable() {
    final bookingDate = _currentBookingDetails['date'];
    final formattedBookingDate = bookingDate is DateTime
        ? DateFormat('MM/dd/yyyy').format(bookingDate)
        : 'N/A';

    final booking = {
      'date': formattedBookingDate,
      'mode': _currentBookingDetails['mode'] ?? 'unknown',
      'driver': _currentBookingDetails['driver'] ?? 'Not Yet Assigned',
      'vehicle': _currentBookingDetails['vehicle'] ?? 'Not Yet Assigned',
      'status': _currentBookingDetails['status'] ?? 'booked',
      'category': _currentBookingDetails['category'] ?? '',
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
                  booking['mode'] == 'donate'
                      ? 'Total Price: ₱0'
                      : (booking['category'] == 'business'
                          ? 'Total Price: ₱${booking['total_price']}'
                          : 'Total Price: ₱${booking['total_price']} - 40 = ₱${booking['calculated_total_price']}'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSquareButton(
                      context: context,
                      text: 'Sell your segregated recyclable trash to trashure',
                      screen: const BookingScreen(mode: 'booking'),
                    ),
                    const SizedBox(width: 20),
                    _buildSquareButton(
                      context: context,
                      text:
                          'Donate your segregated recyclable trash to trashure',
                      screen: const BookingScreen(mode: 'donate'),
                    ),
                  ],
                ),
              ],
            ),
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
