import 'dart:convert'; // For jsonDecode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:trashure/components/appbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // For address handling
import 'package:geolocator/geolocator.dart'; // For user location
import 'package:http/http.dart' as http;
import 'package:trashure/components/booking_history.dart';
import 'package:trashure/components/firebase_options.dart';
import 'package:trashure/components/footer.dart';
import 'package:trashure/screens/bookpreview_screen.dart'; // Import your BookingPreviewScreen
import 'package:flutter/services.dart'; // For TextInputFormatter

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final Map<String, ValueNotifier<double>> _productQuantities = {};
  final Map<String, double> _productPrices = {};
  final Map<String, Timestamp> _productTimestamps = {};
  final Map<String, String> _productDescriptions = {};
  final Map<String, String> _productCategories = {};
  final Map<String, String> _productIds = {};
  final Map<String, String> _productImages = {};

  final ValueNotifier<double> _totalEstimatedProfit =
      ValueNotifier<double>(0.0);

  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  String? currentAddress;
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);
  final TextEditingController _defaultAddressController =
      TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _contactController =
      TextEditingController();

  bool _canBook = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAddressFromFirestore(); // Fetch address and location from Firestore
      await _getUserLocation();
      await _checkBookingAvailability(); // Check if the user can book
    });
  }

  @override
  void dispose() {
    _defaultAddressController.dispose();
    _landmarkController.dispose();
    _contactController.dispose(); // Dispose the contact controller
    _totalEstimatedProfit.dispose(); // Dispose the ValueNotifier
    super.dispose();
  }

  // Fetch address, contact, and location from Firestore
  Future<void> _fetchAddressFromFirestore() async {
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userData.exists) {
          String fetchedAddress = userData.get('address') ?? '';
          String fetchedContact =
              userData.get('contact') ?? ''; // Fetch the contact field
          GeoPoint fetchedLocation =
              userData.get('location') ?? GeoPoint(7.0731, 125.6122);

          LatLng fetchedLatLng =
              LatLng(fetchedLocation.latitude, fetchedLocation.longitude);

          setState(() {
            currentAddress = fetchedAddress;
            _defaultAddressController.text = fetchedAddress;
            _contactController.text =
                fetchedContact; // Set the contact controller
            currentPosition = fetchedLatLng;
          });

          // Update the map
          mapController?.animateCamera(CameraUpdate.newLatLng(fetchedLatLng));
          _addMarker(fetchedLatLng, fetchedAddress);
        }
      } catch (e) {
        print('Error fetching address and location from Firestore: $e');
      }
    }
  }

  // Fetch the current user's location
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentAddress = 'Location services are disabled.';
      });
      return;
    }

    // Request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          currentAddress = 'Location permissions are denied.';
        });
        return;
      }
    }

    // Get the current position if there's no stored location
    if (currentPosition == null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Fetch the address for the current location
      await _getAddressFromLatLng(currentPosition!);

      // Move the map camera to the current position
      mapController?.animateCamera(CameraUpdate.newLatLng(currentPosition!));
      _addMarker(currentPosition!, currentAddress!);
    }
  }

  // Method to get the address from LatLng using geocoding
  Future<void> _getAddressFromLatLng(LatLng position) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'];
          setState(() {
            currentAddress = formattedAddress; // Update currentAddress
            _defaultAddressController.text =
                formattedAddress; // Update text field with address
          });
        } else {
          setState(() {
            currentAddress = 'No address found';
            _defaultAddressController.text = 'No address found';
          });
        }
      } else {
        setState(() {
          currentAddress = 'Error fetching address: ${response.statusCode}';
          _defaultAddressController.text = 'Error fetching address';
        });
      }
    } catch (e) {
      setState(() {
        currentAddress = 'Error fetching address: $e';
        _defaultAddressController.text = 'Error fetching address';
      });
    }
  }

  // Method to get LatLng from an address
  Future<void> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations[0];
        final latLng = LatLng(location.latitude, location.longitude);

        mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

        setState(() {
          _addMarker(latLng, address);
          currentPosition = latLng; // Update currentPosition
        });
      }
    } catch (e) {
      print('Error retrieving location: $e');
    }
  }

  // Add a marker on the map
  void _addMarker(LatLng position, String address) {
    setState(() {
      _markers.clear(); // Clear previous markers
      _markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(
          title: 'Selected Location',
          snippet: address,
        ),
      ));
    });
  }

  // Method to update total estimated profit
  void _updateTotalEstimatedProfit() {
    double totalProfit = 0.0;
    _productQuantities.forEach((productName, notifier) {
      final weight = notifier.value;
      final pricePerKg = _productPrices[productName] ?? 0.0;
      totalProfit += weight * pricePerKg;
    });
    _totalEstimatedProfit.value = totalProfit;
  }

  // New method to check for pending bookings
  Future<bool> _checkIfUserHasPendingBooking() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return false;
    }

    try {
      // Fetch all bookings
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        // Get the 'users' subcollection
        final userDocSnapshot =
            await bookingDoc.reference.collection('users').doc(userId).get();

        if (userDocSnapshot.exists) {
          String userStatus = userDocSnapshot['status'] ?? '';
          if (userStatus == 'scheduled') {
            return true; // User has a pending booking
          }
        }
      }
    } catch (e) {
      print('Error checking pending bookings: $e');
    }

    return false;
  }

  // Method to check booking availability
  Future<void> _checkBookingAvailability() async {
    bool hasPendingBooking = await _checkIfUserHasPendingBooking();
    setState(() {
      _canBook = !hasPendingBooking;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    if (!_canBook) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You have a pending booking.',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
                SizedBox(height: 10),
                Text(
                  'Please wait until your current booking is completed before making a new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BookingHistoryScreen()),
                    );
                  },
                  child: Text('View Booking History'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('category').snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.hasError) {
              return const Text('Error loading categories');
            }

            final categories = categorySnapshot.data?.docs ?? [];

            return DefaultTabController(
              length: categories
                  .length, // Dynamically set the number of tabs based on categories
              child: Scaffold(
                appBar: CustomAppBar(),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Product Selection Section
                      _buildSectionTitle('SELECT YOUR RECYCLABLES'),
                      const SizedBox(height: 10),
                      Container(
                        height: 4,
                        width: isMobile
                            ? MediaQuery.of(context).size.width * 0.8
                            : 400,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 20),
                      // Tabs
                      Container(
                        color: Colors.green[100],
                        child: TabBar(
                          indicatorColor: Colors.green[700],
                          labelColor: Colors.green[700],
                          unselectedLabelColor: Colors.black54,
                          tabs: categories.map((categoryDoc) {
                            return Tab(
                                text: categoryDoc[
                                    'category_name']); // Each tab title is based on category name
                          }).toList(),
                        ),
                      ),
                      Container(
                        height: isMobile ? 800 : 600, // Adjust height as needed
                        child: TabBarView(
                          children: categories.map((categoryDoc) {
                            final categoryName = categoryDoc[
                                'category_name']; // Get the name of the category
                            return _buildProductsSection(
                                context, categoryName, isMobile);
                          }).toList(),
                        ),
                      ),
                      // Display Total Estimated Profit
                      Column(
                        children: [
                          Text(
                            'Minimum booking amount: ₱200',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          ValueListenableBuilder<double>(
                            valueListenable: _totalEstimatedProfit,
                            builder: (context, totalProfit, child) {
                              return Text(
                                'Total Estimated Profit: ₱${totalProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: totalProfit >= 150.0
                                      ? Colors.green[700]
                                      : Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),
                      _buildSectionTitle('VERIFY YOUR ADDRESS'),
                      const SizedBox(height: 10),
                      Container(
                        height: 4,
                        width: isMobile
                            ? MediaQuery.of(context).size.width * 0.8
                            : 400,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 20),
                      _buildAddressSection(context, isMobile),
                      const SizedBox(height: 20),
                      // Next Button
                      ElevatedButton(
                        onPressed: () async {
                          if (_totalEstimatedProfit.value < 200.0) {
                            // Show prompt
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please add more recyclables to reach the minimum amount of ₱200.'),
                              ),
                            );
                            return;
                          }

                          // Collect selected items
                          Map<String, dynamic> selectedItems = {};

                          _productQuantities.forEach((productName, notifier) {
                            if (notifier.value > 0) {
                              final productPrice = _productPrices[productName];
                              final priceTimestamp =
                                  _productTimestamps[productName];
                              final productDescription =
                                  _productDescriptions[productName];
                              final productImage = _productImages[productName];
                              final productCategory = _productCategories[
                                  productName]; // Fetch stored category
                              final productId = _productIds[
                                  productName]; // Fetch stored document ID

                              selectedItems[productName] = {
                                'weight': notifier.value,
                                'price_per_kg': productPrice,
                                'total_price': notifier.value * productPrice!,
                                'price_timestamp': priceTimestamp,
                                'description': productDescription,
                                'image': productImage,
                                'category': productCategory, // New field
                                'product_Id': productId, // New field
                              };
                            }
                          });

                          if (selectedItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please select at least one item.')),
                            );
                            return;
                          }

                          final address = _defaultAddressController.text;
                          final landmark = _landmarkController.text;
                          final contact = _contactController.text;
                          final fullAddress = '$address, Landmark: $landmark';

                          // Optionally, update Firestore with the new data
                          if (user != null) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .update({
                                'address': address,
                                'landmark': landmark,
                                'contact': contact,
                                'location': GeoPoint(
                                    currentPosition?.latitude ?? 0.0,
                                    currentPosition?.longitude ?? 0.0),
                              });
                            } catch (e) {
                              print('Error updating Firestore: $e');
                            }
                          }

                          // Navigate to BookingPreviewScreen with the selected items
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPreviewScreen(
                                selectedItems: selectedItems,
                                address: fullAddress,
                                contact: contact,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: isMobile
                              ? const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12)
                              : const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Next',
                            style: TextStyle(color: Colors.white)),
                      ),

                      const SizedBox(height: 20),
                      const Footer(),
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

  // Widget to build the address confirmation section
  Widget _buildAddressSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      // Mobile layout
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Map
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: currentPosition ?? _initialPosition,
                  zoom: 15,
                ),
                markers: _markers,
                onTap: (LatLng position) async {
                  // Add marker on the map at the tapped location
                  _addMarker(
                      position, '${position.latitude}, ${position.longitude}');

                  // Fetch address from LatLng and update the address field
                  await _getAddressFromLatLng(position);

                  // Update currentPosition with the tapped location
                  setState(() {
                    currentPosition = position;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Text fields
            _buildAddressFields(),
          ],
        ),
      );
    } else {
      // Desktop layout
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Map on the left side
            Expanded(
              flex: 4,
              child: Container(
                height: 450,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentPosition ?? _initialPosition,
                    zoom: 15,
                  ),
                  markers: _markers,
                  onTap: (LatLng position) async {
                    // Add marker on the map at the tapped location
                    _addMarker(position,
                        '${position.latitude}, ${position.longitude}');

                    // Fetch address from LatLng and update the address field
                    await _getAddressFromLatLng(position);

                    // Update currentPosition with the tapped location
                    setState(() {
                      currentPosition = position;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text fields on the right side
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _buildAddressFields(),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Default Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _defaultAddressController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter default address',
          ),
          onSubmitted: (value) {
            _getLatLngFromAddress(value); // Fetch LatLng from address
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'House no., Landmark, etc.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _landmarkController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter landmark or house no.',
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contactController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter phone number',
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // Product selection methods
  Widget _buildProductsSection(
    BuildContext context,
    String category,
    bool isMobile,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading products');
        }

        final products = snapshot.data?.docs ?? [];

        if (products.isEmpty) {
          return const Text('No products available in this category.');
        }

        return SingleChildScrollView(
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: products.map((productDoc) {
              final productData = productDoc.data() as Map<String, dynamic>;
              final productName = productData['product_name'].toUpperCase();
              final productDescription = productData['details'];
              final productImageFile = productData['picture'];
              final productCategory = productData['category']; // Fetch category
              final productId = productDoc.id; // Fetch document ID

              // Save category and product ID for each product name
              _productCategories[productName] = productCategory;
              _productIds[productName] = productId;

              // Use StreamBuilder to listen for real-time updates to prices
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productDoc.id)
                    .collection('prices')
                    .orderBy('time', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, priceSnapshot) {
                  if (!priceSnapshot.hasData ||
                      priceSnapshot.data!.docs.isEmpty) {
                    return const Text('Price unavailable');
                  }

                  final priceData = priceSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                  final productPrice = priceData['price'] as double;
                  final priceTimestamp = priceData['time'] as Timestamp;

                  // Initialize weight and price for each product if not set
                  _productQuantities.putIfAbsent(
                      productName, () => ValueNotifier<double>(0));
                  _productPrices.putIfAbsent(productName, () => productPrice);
                  _productTimestamps.putIfAbsent(
                      productName, () => priceTimestamp);

                  // Store product descriptions and images for later use
                  _productDescriptions.putIfAbsent(
                      productName, () => productDescription);
                  _productImages.putIfAbsent(
                      productName, () => productImageFile);

                  // Pass category and document ID to _buildProductCard
                  return _buildProductCard(
                    context,
                    productName,
                    productDescription,
                    productPrice,
                    productImageFile,
                    priceTimestamp,
                    productCategory, // Pass category
                    productId, // Pass product ID
                    isMobile,
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Build product card with Firebase Storage image
  Widget _buildProductCard(
    BuildContext context,
    String title,
    String description,
    double pricePerKg,
    String imageFileName,
    Timestamp priceTimestamp,
    String category, // New parameter for category
    String documentId, // New parameter for document ID
    bool isMobile,
  ) {
    // Controller to manage the input for weight
    TextEditingController weightController = TextEditingController();

    // Initialize with the current weight value
    weightController.text = _productQuantities[title]!.value.toStringAsFixed(2);

    return SizedBox(
      width: isMobile
          ? MediaQuery.of(context).size.width * 0.9
          : (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: isMobile
              ? const EdgeInsets.all(10.0)
              : const EdgeInsets.all(20.0),
          child: Column(
            children: [
              FutureBuilder<String>(
                future: _fetchImageFromFirebaseStorage(
                    imageFileName), // Fetch image URL
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading image');
                  }
                  if (!snapshot.hasData) {
                    return const Text('Image not available');
                  }

                  final imageUrl =
                      snapshot.data!; // URL of the image from Firebase Storage

                  return Row(
                    children: [
                      Expanded(
                        flex: isMobile ? 4 : 3,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: Image.network(
                            imageUrl,
                            height: isMobile ? 100 : 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: isMobile ? 6 : 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₱ ${pricePerKg.toStringAsFixed(2)} / kg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '₱ ${pricePerKg.toStringAsFixed(2)} / kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Divider(thickness: 1, color: Colors.green[100]),
              ValueListenableBuilder<double>(
                valueListenable: _productQuantities[title]!,
                builder: (context, weight, child) {
                  // Update the text field when the weight changes
                  weightController.text = weight.toStringAsFixed(2);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.green[700]),
                        onPressed: () {
                          if (weight > 0) {
                            double newWeight =
                                (weight - 0.1).clamp(0.0, double.infinity);
                            // Round to two decimal places
                            newWeight =
                                double.parse(newWeight.toStringAsFixed(2));
                            _productQuantities[title]!.value = newWeight;
                            _updateTotalEstimatedProfit();
                          }
                        },
                      ),
                      // TextField to input the weight
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            // Update the weight value when the text changes
                            double? newWeight = double.tryParse(value);
                            if (newWeight != null) {
                              // Round to two decimal places
                              newWeight =
                                  double.parse(newWeight.toStringAsFixed(2));
                              _productQuantities[title]!.value = newWeight;
                              _updateTotalEstimatedProfit();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green[700]),
                        onPressed: () {
                          double newWeight =
                              _productQuantities[title]!.value + 0.1;
                          // Round to two decimal places
                          newWeight =
                              double.parse(newWeight.toStringAsFixed(2));
                          _productQuantities[title]!.value = newWeight;
                          _updateTotalEstimatedProfit();
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Estimated Profit',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '₱ ${(pricePerKg * weight).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to fetch image from Firebase Storage
  Future<String> _fetchImageFromFirebaseStorage(String fileName) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('product_images/$fileName');
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error fetching image: $e');
      return ''; // Return an empty string in case of an error
    }
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

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Trashure - Login Required',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You need to be logged in to proceed.',
              style: TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Login Now',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
