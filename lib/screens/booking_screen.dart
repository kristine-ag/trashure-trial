import 'dart:convert'; // For jsonDecode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // For address handling
import 'package:geolocator/geolocator.dart'; // For user location
import 'package:http/http.dart' as http;
import 'package:trashure/components/firebase_options.dart';
import 'package:trashure/screens/bookpreview_screen.dart'; // Import your BookingPreviewScreen

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Variables for product selection
  bool _showAllPlastics = false;
  bool _showAllMetals = false;

  final user = FirebaseAuth.instance.currentUser;

  // Map to track quantities for products dynamically
  final Map<String, ValueNotifier<int>> _productQuantities = {};

  // Map to track product prices dynamically
  final Map<String, double> _productPrices = {};

  // Map to track product timestamps dynamically
  final Map<String, Timestamp> _productTimestamps = {};

  // Map to track product descriptions dynamically
  final Map<String, String> _productDescriptions = {};

  // Map to track product images dynamically
  final Map<String, String> _productImages = {};

  // Variables for address confirmation
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  String? currentAddress;
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);
  final TextEditingController _defaultAddressController =
      TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _contactController =
      TextEditingController(); // Controller for phone number

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAddressFromFirestore(); // Fetch address and location from Firestore
      await _getUserLocation();
    });
  }

  @override
  void dispose() {
    // Dispose product selection controllers if any
    _defaultAddressController.dispose();
    _landmarkController.dispose();
    _contactController.dispose(); // Dispose the contact controller
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
          currentAddress = formattedAddress;  // Update currentAddress
          _defaultAddressController.text = formattedAddress;  // Update text field with address
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

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Selection Section
            _buildSectionTitle('SELECT PRODUCTS'),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 10),
            _buildSectionTitle('PLASTICS'),
            const SizedBox(height: 10),
            _buildProductsSection(context, 'plastics', _showAllPlastics, () {
              setState(() {
                _showAllPlastics = !_showAllPlastics;
              });
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('METALS'),
            const SizedBox(height: 10),
            _buildProductsSection(context, 'metals', _showAllMetals, () {
              setState(() {
                _showAllMetals = !_showAllMetals;
              });
            }),
            const SizedBox(height: 20),

            // Address Confirmation Section
            _buildSectionTitle('CONFIRM YOUR ADDRESS'),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 20),
            _buildAddressSection(context),
            const SizedBox(height: 20),
            // Next Button
            ElevatedButton(
              onPressed: () async {
                // Collect selected items
                Map<String, dynamic> selectedItems = {};

                _productQuantities.forEach((productName, notifier) {
                  if (notifier.value > 0) {
                    final productPrice = _productPrices[productName];
                    final priceTimestamp = _productTimestamps[productName];
                    final productDescription =
                        _productDescriptions[productName];
                    final productImage = _productImages[productName];

                    selectedItems[productName] = {
                      'weight': notifier.value,
                      'price_per_kg': productPrice,
                      'total_price': notifier.value * productPrice!,
                      'price_timestamp': priceTimestamp,
                      'description': productDescription,
                      'image': productImage,
                    };
                  }
                });

                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select at least one item.')),
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
                      'location': GeoPoint(currentPosition?.latitude ?? 0.0,
                          currentPosition?.longitude ?? 0.0),
                    });
                  } catch (e) {
                    print('Error updating Firestore: $e');
                  }
                }

                // Navigate to BookingPreviewScreen
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Next', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Widget to build the address confirmation section
  Widget _buildAddressSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
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
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Container(
              height: 400,
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
          ),
        ],
      ),
    );
  }

  // The rest of your BookingScreen code (product selection methods)
  Widget _buildProductsSection(BuildContext context, String category,
      bool showAll, VoidCallback toggleShowAll) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error loading products');
        }

        final products = snapshot.data?.docs ?? [];

        if (products.isEmpty) {
          return const Text('No products available in this category.');
        }

        // Show either 2 cards or all cards based on `showAll`
        final visibleProducts = showAll ? products : products.take(2).toList();

        return Column(
          children: [
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: visibleProducts.map((productDoc) {
                final productData = productDoc.data() as Map<String, dynamic>;
                final productName = productData['product_name'].toUpperCase();
                final productDescription = productData['details'];
                final productImage = productData['picture'];

                // Fetch the latest price from the subcollection "prices"
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .doc(productDoc.id)
                      .collection('prices')
                      .orderBy('time', descending: true)
                      .limit(1)
                      .get(),
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
                        productName, () => ValueNotifier<int>(0));
                    _productPrices.putIfAbsent(productName, () => productPrice);
                    _productTimestamps.putIfAbsent(
                        productName, () => priceTimestamp);

                    // Store product descriptions and images for later use
                    _productDescriptions.putIfAbsent(
                        productName, () => productDescription);
                    _productImages.putIfAbsent(productName, () => productImage);

                    return _buildProductCard(
                        context,
                        productName,
                        productDescription,
                        productPrice,
                        productImage,
                        priceTimestamp);
                  },
                );
              }).toList(),
            ),
            _buildToggleButton(
                showAll, 'See more...', 'See less...', toggleShowAll),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String title,
    String description,
    double pricePerKg,
    String imageUrl,
    Timestamp priceTimestamp,
  ) {
    // Controller to manage the input for weight
    TextEditingController weightController = TextEditingController();

    // Initialize with the current weight value
    weightController.text = _productQuantities[title]!.value.toString();

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) /
          2, // Adjust width for two columns
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: Image.network(
                        imageUrl,
                        height: 150, // Set height to match the content
                        fit: BoxFit.cover, // Cover the entire available space
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₱ ${pricePerKg.toStringAsFixed(1)} / kg',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              Divider(thickness: 1, color: Colors.green[100]),
              ValueListenableBuilder<int>(
                valueListenable: _productQuantities[title]!,
                builder: (context, weight, child) {
                  // Update the text field when the weight changes
                  weightController.text = weight.toString();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.green[700]),
                        onPressed: () {
                          if (weight > 0) {
                            _productQuantities[title]!.value -= 1;
                          }
                        },
                      ),
                      // TextField to input the weight
                      SizedBox(
                        width: 50,
                        height: 40,
                        child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // Update the weight value when the text changes
                            int? newWeight = int.tryParse(value);
                            if (newWeight != null) {
                              _productQuantities[title]!.value = newWeight;
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green[700]),
                        onPressed: () {
                          _productQuantities[title]!.value += 1;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Estimated Profit',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '₱ ${(pricePerKg * weight).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 18,
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

  Widget _buildToggleButton(
      bool showAll, String moreText, String lessText, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          showAll ? lessText : moreText,
          style: TextStyle(color: Colors.green[700]),
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterColumn('Our Scope',
              ['Sample District 1', 'Sample District 2', 'Sample District 3']),
          _buildFooterColumn(
              'Our Partners', ['Lalala Inc.', 'Trash R Us', 'SM Cares']),
          _buildFooterColumn('About Us', ['Our Story', 'Work with us']),
          _buildFooterColumn('Contact Us', ['Our Story', 'Work with us']),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
