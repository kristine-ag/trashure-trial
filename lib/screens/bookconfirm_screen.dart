import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/footer.dart';
import 'package:intl/intl.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;
  final Map<String, dynamic> selectedItems;
  const BookingConfirmedScreen({
    super.key,
    required this.bookingDetails,
    required this.selectedItems,
  });

  @override
  _BookingConfirmedScreenState createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  Map<String, dynamic> _currentBookingDetails = {};
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('date', descending: true) // Sort by date in descending order
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final userDocSnapshot =
            await bookingDoc.reference.collection('users').doc(userId).get();

        if (userDocSnapshot.exists && userDocSnapshot['status'] == 'booked') {
          // Set _bookingId when a valid booking is found
          setState(() {
            _bookingId = bookingDoc.id; // Assign booking ID
          });

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
              'user_category': userDocSnapshot['category'],
              'user_status': userDocSnapshot['status'],
              'status': bookingDoc['status'],
              'recyclables': recyclables,
              'total_weight': userDocSnapshot['total_weight'] ?? 0.0,
              'total_price': userDocSnapshot['total_price'] ?? 0.0,
              'calculated_total_price':
                  userDocSnapshot['calculated_total_price'] ?? 0.0,
              'mode': userDocSnapshot['mode'] ?? 'unknown',
            };
          });
          return; // Stop after finding the most recent active booking
        }
      }

      // Log if no booking is found
      print("No active booking found for user.");
    } catch (e) {
      print('Error fetching booking details: $e');
    }
  }

  Future<void> _cancelBooking() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Check if _bookingId is null
    if (userId == null || _bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find booking to cancel.')),
      );
      print('_bookingId or userId is null. Cannot cancel booking.');
      return;
    }

    try {
      print(
          'Attempting to cancel booking with ID: $_bookingId for user: $userId');

      // Fetch user's data for adjustments
      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_bookingId)
          .collection('users')
          .doc(userId)
          .get();

      if (!userDocSnapshot.exists) {
        print('User document does not exist under the booking.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found for this user.')),
        );
        return;
      }

      final userData = userDocSnapshot.data();
      double userTotalPrice = userData?['total_price'] ?? 0.0;
      double userTotalWeight = userData?['total_weight'] ?? 0.0;
      double userCalculatedTotalPrice =
          userData?['calculated_total_price'] ?? 0.0;

      final bookingDocRef =
          FirebaseFirestore.instance.collection('bookings').doc(_bookingId);

      final bookingDocSnapshot = await bookingDocRef.get();
      if (bookingDocSnapshot.exists) {
        final bookingData = bookingDocSnapshot.data();

        double overallPrice = bookingData?['overall_price'] ?? 0.0;
        double overallWeight = bookingData?['overall_weight'] ?? 0.0;
        double calculatedOverallPrice =
            bookingData?['calculated_overall_price'] ?? 0.0;

        await bookingDocRef.update({
          'overall_price':
              (overallPrice - userTotalPrice).clamp(0.0, double.infinity),
          'overall_weight':
              (overallWeight - userTotalWeight).clamp(0.0, double.infinity),
          'calculated_overall_price':
              (calculatedOverallPrice - userCalculatedTotalPrice)
                  .clamp(0.0, double.infinity),
        });
      }

      final recyclablesCollection = bookingDocRef
          .collection('users')
          .doc(userId)
          .collection('recyclables');
      final recyclablesSnapshot = await recyclablesCollection.get();

      for (var recyclableDoc in recyclablesSnapshot.docs) {
        await recyclableDoc.reference.delete();
      }

      await bookingDocRef.collection('users').doc(userId).delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'status': 'unbooked'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking successfully canceled!')),
      );

      Navigator.pushNamed(context, '/Book');
    } catch (e) {
      print('Error canceling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling booking: $e')),
      );
    }
  }

  void _showCancelConfirmationModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the modal
                await _cancelBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCancelConfirmationModal,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'CANCEL BOOKING',
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
                  _currentBookingDetails['mode'] == 'donate'
                      ? 'Total Price: ₱0'
                      : (_currentBookingDetails['user_category'] == 'business'
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
}
