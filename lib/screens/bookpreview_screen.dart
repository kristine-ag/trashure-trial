import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user details
import 'package:intl/intl.dart'; // For formatting dates
import 'package:trashure/screens/bookconfirm_screen.dart';
import '../components/appbar.dart';

class BookingPreviewScreen extends StatefulWidget {
  final String mode;
  final Map<String, dynamic> selectedItems;
  final String address;
  final String contact;
  final String district;

  const BookingPreviewScreen({
    Key? key,
    required this.mode,
    required this.selectedItems,
    required this.address,
    required this.contact,
    required this.district,
  }) : super(key: key);

  @override
  _BookingPreviewAndScheduleScreenState createState() =>
      _BookingPreviewAndScheduleScreenState();
}

class _BookingPreviewAndScheduleScreenState
    extends State<BookingPreviewScreen> {
  bool get isDonateMode => widget.mode == 'donate';
  String? selectedBookingId;
  String? selectedSchedule;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Set<String> userBookedDates =
      {}; // Stores booking IDs where the user has already booked

  @override
  void initState() {
    super.initState();
    fetchUserBookedDates();
  }

  Stream<QuerySnapshot> fetchBookings() {
    DateTime currentDate = DateTime.now();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentDate))
        .snapshots();
  }

  // Function to fetch booking IDs where the user has already booked
  void fetchUserBookedDates() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final uid = user.uid;
    Set<String> bookedDates = {};

    QuerySnapshot bookingsSnapshot =
        await FirebaseFirestore.instance.collection('bookings').get();

    for (var bookingDoc in bookingsSnapshot.docs) {
      DocumentSnapshot userDoc =
          await bookingDoc.reference.collection('users').doc(uid).get();
      if (userDoc.exists) {
        bookedDates.add(bookingDoc.id);
      }
    }

    setState(() {
      userBookedDates = bookedDates;
    });
  }

  Future<void> submitBooking(String bookingId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final uid = user.uid;
      final donated = 0;

      // Retrieve the user's document to add user data to booking
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception("User data not found.");
      }
      final userData = userDoc.data()!;

      // Remove sensitive fields if needed
      final filteredUserData = Map<String, dynamic>.from(userData);
      filteredUserData.remove('balance');

      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final userRef = bookingRef.collection('users').doc(uid);

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Store basic user info in the user document
      batch.set(userRef, filteredUserData);

      double totalUserPrice = 0;
      double totalUserWeight = 0;

      // Calculate totalEstimatedProfit based on selected items
      double totalEstimatedProfit = widget.selectedItems.entries.fold(
        0.0,
        (previousValue, entry) {
          double weight = entry.value['weight'] ?? 0.0;
          double pricePerKg = entry.value['price_per_kg'] ?? 0.0;
          return previousValue + (weight * pricePerKg);
        },
      );

      // Deduct collection fee to calculate totalPrice
      const double collectionFee = 40.0;
      double totalPrice = totalEstimatedProfit - collectionFee;

      // Loop through each selected item and add its details to the recyclables subcollection
      for (var entry in widget.selectedItems.entries) {
        double weight = entry.value['weight'] ?? 0.0;
        double pricePerKg = entry.value['price_per_kg'] ?? 0.0;
        double itemPrice = weight * pricePerKg;

        // Format price and itemPrice to two decimal places
        pricePerKg = double.parse(pricePerKg.toStringAsFixed(2));
        itemPrice = double.parse(itemPrice.toStringAsFixed(2));

        totalUserPrice += itemPrice;
        totalUserWeight += weight;

        // New fields for category and documentId, with default values if null
        String category = entry.value['category'] ?? 'Unknown Category';
        String documentId = entry.value['product_Id'] ?? 'Unknown ID';

        // Prepare the recyclable item data
        Map<String, dynamic> recyclableData = {
          'type': entry.key,
          'weight': weight,
          'price': donated, 
          'item_price': donated, 
          'timestamp':
              (entry.value['price_timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
          'category': category,
          'product_Id': documentId,
        };

        // Add original_price only if not in donate mode
        if (!isDonateMode) {
          recyclableData['original_price'] =
              entry.value['original_price'] ?? 0.0;
          recyclableData['price'] =
              entry.value[pricePerKg] ?? 0.0;
          recyclableData['item_price'] =
              entry.value[itemPrice] ?? 0.0;
        }

        // Add each recyclable item with the conditional fields
        batch.set(userRef.collection('recyclables').doc(), recyclableData);
      }

      // Update user document with total price, weight, and calculated_total_price
      batch.update(userRef, {
        'total_price': double.parse(totalUserPrice.toStringAsFixed(2)),
        'total_weight': double.parse(totalUserWeight.toStringAsFixed(2)),
        'calculated_total_price': double.parse(totalPrice.toStringAsFixed(2)),
        'status': "booked",
      });

      // Commit all the changes
      await batch.commit();

      // Calculate and update the booking document's overall price and weight
      final usersSnapshot = await bookingRef.collection('users').get();
      double overallPrice = 0;
      double overallWeight = 0;
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        overallPrice += userData['total_price'] ?? 0;
        overallWeight += userData['total_weight'] ?? 0;
      }

      await bookingRef.update({
        'overall_price': overallPrice,
        'overall_weight': overallWeight,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingConfirmedScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(isDonateMode);
    double totalWeight =
        widget.selectedItems.entries.fold(0.0, (previousValue, element) {
      double itemWeight = (element.value['weight'] ?? 0.0);
      return previousValue + itemWeight;
    });

    double totalEstimatedProfit =
        widget.selectedItems.entries.fold(0.0, (previousValue, element) {
      double itemPrice = (element.value['weight'] ?? 0.0) *
          (element.value['price_per_kg'] ?? 0.0);
      return previousValue + itemPrice;
    });

    // Deduct collection fee
    const double collectionFee = 40.0;
    double totalPrice = totalEstimatedProfit - collectionFee;

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSectionTitle('BOOKING PREVIEW'),
                const SizedBox(height: 30),
                if (constraints.maxWidth > 800)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 6,
                        child: _buildSelectedItemsWithPrices(
                            totalEstimatedProfit, totalPrice),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        flex: 4,
                        child: _buildAddressCard(context),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedItemsWithPrices(
                          totalEstimatedProfit, totalPrice),
                      const SizedBox(height: 30),
                      _buildAddressCard(context),
                    ],
                  ),
                const SizedBox(height: 30),
                _buildTotalWeightAndPriceSection(totalWeight, totalPrice),
                const SizedBox(height: 50),
                _buildSectionTitle('BOOKING SCHEDULE'),
                const SizedBox(height: 30),
                _buildScheduleSection(),
                const SizedBox(height: 30),
                _buildBookNowButton(context),
                const SizedBox(height: 40),
                _buildFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedItemsWithPrices(
      double totalEstimatedProfit, double totalPrice) {
    const double collectionFee = 40.0; // Fixed collection fee

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.selectedItems.entries.map((entry) {
              double itemWeight = entry.value['weight'] ?? 0.0;
              String description =
                  entry.value['description'] ?? 'No description available';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${itemWeight.toStringAsFixed(2)} kg/s',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        if (!isDonateMode) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Total: ₱${(itemWeight * (entry.value['price_per_kg'] ?? 0.0)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            if (!isDonateMode) ...[
              const Divider(
                height: 30,
                thickness: 1,
                color: Colors.grey,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Estimated Profit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${totalEstimatedProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Collection Fee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '-₱${collectionFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTotalWeightAndPriceSection(
      double totalWeight, double totalPrice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Weight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalWeight.toStringAsFixed(2)} kg/s',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (!isDonateMode) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₱${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.address.split(', Landmark: ')[0],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'District',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              widget.district, // Display district here
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Contact Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              widget.contact.isNotEmpty ? widget.contact : 'N/A',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          print('Error fetching bookings: ${snapshot.error}');
          return const Text('Error fetching bookings.');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings available.'));
        }

        // Filter documents by district
        final bookings = snapshot.data!.docs.where((doc) {
          final bookingData = doc.data() as Map<String, dynamic>;
          return bookingData['location'] == widget.district;
        }).toList();

        if (bookings.isEmpty) {
          return const Center(
              child: Text('No bookings available for your district.'));
        }

        return Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Schedules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: bookings.map((bookingDoc) {
                    final bookingData =
                        bookingDoc.data() as Map<String, dynamic>;
                    final Timestamp dateTimestamp = bookingData['date'];
                    final DateTime bookingDate = dateTimestamp.toDate();
                    final String formattedDate =
                        DateFormat('MMMM dd, yyyy').format(bookingDate);
                    final String weekday =
                        DateFormat('EEEE').format(bookingDate);
                    final String bookingId = bookingDoc.id;

                    final String? startTime = bookingData['start_time'];
                    final String? endTime = bookingData['end_time'];

                    bool isAlreadyBooked = userBookedDates.contains(bookingId);

                    return _buildBookingCard(
                      context,
                      bookingId,
                      formattedDate,
                      weekday,
                      isAlreadyBooked,
                      startTime,
                      endTime,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    String date,
    String weekday,
    bool isAlreadyBooked,
    String? startTime,
    String? endTime,
  ) {
    final isSelected = selectedBookingId == bookingId;

    return GestureDetector(
      onTap: isAlreadyBooked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'You already have a scheduled booking for this day.'),
                ),
              );
            }
          : () {
              setState(() {
                selectedBookingId = bookingId;
                selectedSchedule = bookingId;
              });
            },
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: isAlreadyBooked
              ? Colors.grey[300]
              : (isSelected ? const Color(0xFF8DD3BB) : Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (startTime != null && endTime != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Time: $startTime - $endTime',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    if (isAlreadyBooked) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Already booked',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ],
                ),
                isAlreadyBooked
                    ? Icon(
                        Icons.block,
                        color: Colors.red[700],
                      )
                    : Radio(
                        value: bookingId,
                        groupValue: selectedSchedule,
                        onChanged: (value) {
                          setState(() {
                            selectedSchedule = value as String?;
                          });
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (selectedSchedule != null) {
            submitBooking(selectedSchedule!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select a schedule before booking.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 16, 1, 1),
      child: Center(
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: const [
          Text(
            'Thank you for using Trashure!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please recycle responsibly.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
