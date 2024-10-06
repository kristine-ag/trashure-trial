import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user details
import 'package:intl/intl.dart'; // For formatting dates
import 'package:trashure/screens/bookconfirm_screen.dart';
import '../components/appbar.dart';

class BookingPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> selectedItems;
  final String address;
  final String contact;

  const BookingPreviewScreen({
    Key? key,
    required this.selectedItems,
    required this.address,
    required this.contact,
  }) : super(key: key);

  @override
  _BookingPreviewAndScheduleScreenState createState() => _BookingPreviewAndScheduleScreenState();
}

class _BookingPreviewAndScheduleScreenState extends State<BookingPreviewScreen> {
  String? selectedBookingId;
  String? selectedSchedule;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  // Function to fetch bookings from Firestore
  Stream<QuerySnapshot> fetchBookings() {
    return FirebaseFirestore.instance.collection('bookings').snapshots();
  }

  // Function to handle booking submission
  Future<void> submitBooking(String bookingId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final uid = user.uid;

      // Fetch user data from Firestore (excluding balance)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception("User data not found.");
      }
      final userData = userDoc.data()!;

      // Remove 'balance' field if it exists
      final filteredUserData = Map<String, dynamic>.from(userData);
      filteredUserData.remove('balance');

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final userRef = bookingRef.collection('users').doc(uid);

      // Start a batch to perform multiple writes
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add the user data to the sub-collection (excluding 'balance')
      batch.set(userRef, filteredUserData);

      // Calculate total_price and total_weight for the user
      double totalUserPrice = 0;
      double totalUserWeight = 0;

      // Loop through the selected items and add each recyclable item, including the calculated item_price and item_weight
      if (widget.selectedItems != null) {
        for (var entry in widget.selectedItems.entries) {
          double weight = entry.value['weight'];
          double pricePerKg = entry.value['price_per_kg'];
          double itemPrice = weight * pricePerKg; // Calculate item price
          totalUserPrice += itemPrice; // Add to user's total price
          totalUserWeight += weight; // Add to user's total weight

          // Add recyclables to user's sub-collection
          batch.set(userRef.collection('recyclables').doc(), {
            'type': entry.key,
            'weight': weight, // Add item_weight field
            'price': pricePerKg,
            'item_price': itemPrice, // Add item_price field
            'timestamp': (entry.value['price_timestamp'] as Timestamp).toDate(),
          });
        }

        // Add total_price and total_weight to the user document
        batch.update(userRef, {
          'total_price': totalUserPrice,
          'total_weight': totalUserWeight, // Add total_weight field
        });
      }

      // Commit the batch
      await batch.commit();

      // Now, calculate the overall price and overall weight for the booking by summing all users' total prices and weights
      final usersSnapshot = await bookingRef.collection('users').get();
      double overallPrice = 0;
      double overallWeight = 0;
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        overallPrice += userData['total_price'] ?? 0;
        overallWeight += userData['total_weight'] ?? 0; // Sum the total weights
      }

      // Update the overall_price and overall_weight fields in the bookings document
      await bookingRef.update({
        'overall_price': overallPrice,
        'overall_weight': overallWeight, // Add overall_weight field
      });

      // Show a confirmation message and navigate to BookingConfirmedScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );

      // Navigate to Booking Confirmed Screen
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
    // Calculate the total weight and total price of the selected items
    double totalWeight = widget.selectedItems.entries.fold(0.0, (previousValue, element) {
      // Use null-aware operators to safely handle null values
      double itemWeight = (element.value['weight'] ?? 0.0) * 1.0;
      return previousValue + itemWeight;
    });

    double totalPrice = widget.selectedItems.entries.fold(0.0, (previousValue, element) {
      double itemPrice = (element.value['weight'] ?? 0.0) * (element.value['price_per_kg'] ?? 0.0);
      return previousValue + itemPrice;
    });

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and separator
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'BOOKING PREVIEW',
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
                const SizedBox(height: 30),

                // Handle layout based on screen width
                if (constraints.maxWidth > 800)
                  // For larger screens, display cards in a Row (side by side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Items takes 60% of the screen
                      Flexible(
                        flex: 6,
                        child: _buildSelectedItemsWithPrices(),
                      ),
                      const SizedBox(width: 20), // Add spacing between the cards

                      // Address Card takes 40% of the screen
                      Flexible(
                        flex: 4,
                        child: _buildAddressCard(context),
                      ),
                    ],
                  )
                else
                  // For smaller screens, stack them vertically
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedItemsWithPrices(),
                      const SizedBox(height: 30),
                      _buildAddressCard(context),
                    ],
                  ),
                const SizedBox(height: 30),

                // Total Weight and Price Section
                _buildTotalWeightAndPriceSection(totalWeight, totalPrice),

                const SizedBox(height: 30),

                // Schedule Selection
                _buildSectionTitle('BOOKING SCHEDULE'),
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 400,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 30),
                _buildScheduleSection(),

                const SizedBox(height: 30),

                // Book Now Button
                _buildBookNowButton(context),

                const SizedBox(height: 40),

                // Footer
                _buildFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget to display selected items along with their quantities, prices, and total price per item
  Widget _buildSelectedItemsWithPrices() {
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
              double itemWeight = entry.value['weight'] ?? 0.0; // Handle null weight
              double pricePerKg = entry.value['price_per_kg'] ?? 0.0; // Handle null price
              double totalPriceForItem = itemWeight * pricePerKg;
              String description = entry.value['description'] ?? 'No description available';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Use Expanded to prevent overflow
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
                        Text(
                          '₱${pricePerKg.toStringAsFixed(2)}/kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Total: ₱${totalPriceForItem.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Widget to display address details
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
              'House no., Landmark, etc.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              widget.address.split(', Landmark: ').length > 1
                  ? widget.address.split(', Landmark: ')[1]
                  : 'N/A', // Display landmark if available
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

  // Widget to display total weight and total price
  Widget _buildTotalWeightAndPriceSection(double totalWeight, double totalPrice) {
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
        ],
      ),
    );
  }

  // Widget to build the schedule selection section
  Widget _buildScheduleSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error fetching bookings.');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings available.'));
        }

        final bookings = snapshot.data!.docs;

        return Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    final bookingData = bookingDoc.data() as Map<String, dynamic>;
                    final Timestamp dateTimestamp = bookingData['date'];
                    final DateTime bookingDate = dateTimestamp.toDate();
                    final String formattedDate = DateFormat('MMMM dd, yyyy').format(bookingDate);
                    final String weekday = DateFormat('EEEE').format(bookingDate);
                    final String bookingId = bookingDoc.id;

                    return _buildBookingCard(
                      context,
                      bookingId,
                      formattedDate,
                      weekday,
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
  ) {
    final isSelected = selectedBookingId == bookingId;

    return GestureDetector(
      onTap: () {
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
          color: isSelected ? const Color(0xFF8DD3BB) : Colors.white,
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
                    const SizedBox(height: 10),
                  ],
                ),
                Radio(
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

  // Book Now Button
  Widget _buildBookNowButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (selectedSchedule != null) {
            submitBooking(selectedSchedule!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a schedule before booking.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // Footer widget
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
