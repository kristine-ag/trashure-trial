import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trashure/components/appbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:trashure/components/firebase_options.dart';
import 'package:trashure/screens/bookpreview_screen.dart';
import 'package:flutter/services.dart';
import 'package:trashure/components/footer.dart';

class BookingScreen extends StatefulWidget {
  final String mode;
  const BookingScreen({Key? key, required this.mode}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool get isDonateMode => widget.mode == 'donate';
  final user = FirebaseAuth.instance.currentUser;
  final Map<String, ValueNotifier<double>> _productQuantities = {};
  final Map<String, double> _productPrices = {};
  final Map<String, Timestamp> _productTimestamps = {};
  final Map<String, String> _productDescriptions = {};
  final Map<String, double> _originalPrices = {};
  final Map<String, String> _productCategories = {};
  final Map<String, String> _productIds = {};
  final Map<String, String> _productImages = {};
  final ValueNotifier<double> _totalEstimatedProfit =
      ValueNotifier<double>(0.0);
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  String? currentAddress;
  String? _selectedArea;
  final LatLng _initialPosition = const LatLng(7.0731, 125.6122);
  final TextEditingController _defaultAddressController =
      TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  double minimumBookingAmount = 200.0; // Default for regular users

  final List<String> _areas = [
    'POBLACION',
    'TALOMO',
    'AGDAO',
    'BUHANGIN',
    'BUNAWAN',
    'PAQUIBATO',
    'BAGUIO',
    'CALINAN',
    'MARILOG',
    'TORIL',
    'TUGBOK'
  ];

  String _truncateDescription(String description, int wordLimit) {
    List<String> words = description.split(' ');
    if (words.length > wordLimit) {
      return words.take(wordLimit).join(' ') + '...';
    } else {
      return description;
    }
  }

  CameraPosition _cameraPosition = CameraPosition(
    target: LatLng(7.0731, 125.6122),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAddressFromFirestore();
    });
  }

  @override
  void dispose() {
    _defaultAddressController.dispose();
    _landmarkController.dispose();
    _contactController.dispose();
    _totalEstimatedProfit.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressFromFirestore() async {
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (userData.exists) {
          String fetchedAddress = userData.get('address') ?? '';
          String fetchedContact = userData.get('contact') ?? '';
          String fetchedLandmark = userData.get('landmark') ?? '';

          GeoPoint fetchedLocation =
              userData.get('location') ?? GeoPoint(7.0731, 125.6122);
          LatLng fetchedLatLng =
              LatLng(fetchedLocation.latitude, fetchedLocation.longitude);

          // Check the user's category and update the minimum amount if they are a business user
          String userCategory = userData.get('category') ?? '';
          if (userCategory == 'business') {
            setState(() {
              minimumBookingAmount = 500.0;
            });
          }

          setState(() {
            currentAddress = fetchedAddress;
            _defaultAddressController.text = fetchedAddress;
            _contactController.text = fetchedContact;
            _landmarkController.text = fetchedLandmark;
            currentPosition = fetchedLatLng;
            _cameraPosition = CameraPosition(target: fetchedLatLng, zoom: 15);
          });

          mapController?.animateCamera(CameraUpdate.newLatLng(fetchedLatLng));
          _addMarker(fetchedLatLng, fetchedAddress);
          _updateDistrict(fetchedAddress);
        }
      } catch (e) {
        print('Error fetching address and location from Firestore: $e');
      }
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentAddress = 'Location services are disabled.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

    if (currentPosition == null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
      await _getAddressFromLatLng(currentPosition!);
      mapController?.animateCamera(CameraUpdate.newLatLng(currentPosition!));
      _addMarker(currentPosition!, currentAddress!);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${googleMapsApiKey}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'];
          setState(() {
            currentAddress = formattedAddress;
            _defaultAddressController.text =
                formattedAddress; // Update the text field
            _updateDistrict(formattedAddress);
          });
        }
      }
    } catch (e) {
      setState(() {
        currentAddress = 'Error fetching address: $e';
        _defaultAddressController.text = 'Error fetching address';
      });
    }
  }

  Future<void> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations[0];
        final latLng = LatLng(location.latitude, location.longitude);

        mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        setState(() {
          _addMarker(latLng, address);
          currentPosition = latLng;
        });
      }
    } catch (e) {
      print('Error retrieving location: $e');
    }
  }

  void _updateDistrict(String address) {
    for (var area in _areas) {
      if (address.toUpperCase().contains(area)) {
        setState(() {
          _selectedArea = area;
        });
        break;
      }
    }
  }

  void _updateTotalEstimatedProfit() {
    double totalProfit = 0.0;
    _productQuantities.forEach((productName, notifier) {
      final weight = notifier.value;
      final pricePerKg = _productPrices[productName] ?? 0.0;
      totalProfit += weight * pricePerKg;
    });
    _totalEstimatedProfit.value = totalProfit;
  }

  Future<String> _fetchImageFromFirebaseStorage(String fileName) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('product_images/$fileName');
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error fetching image: $e');
      return '';
    }
  }

  void _addMarker(LatLng position, String address) {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(title: 'Selected Location', snippet: address),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return _buildLoginPrompt(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return FutureBuilder<List<DocumentSnapshot>>(
          future:
              _getCategoriesWithProducts(), // Fetch categories with products
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading categories'));
            }

            final categories = snapshot.data ?? [];

            return DefaultTabController(
              length: categories.length,
              child: Scaffold(
                appBar: CustomAppBar(),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSectionTitle('SELECT YOUR RECYCLABLES'),
                      Container(
                        height: 4,
                        width: isMobile
                            ? MediaQuery.of(context).size.width * 0.8
                            : 400,
                        color: Colors.green[700],
                      ),
                      SizedBox(height: 20),
                      Container(
                        color: Colors.green[100],
                        child: TabBar(
                          indicatorColor: Colors.green[700],
                          labelColor: Colors.green[700],
                          unselectedLabelColor: Colors.black54,
                          tabs: categories.map((categoryDoc) {
                            return Tab(text: categoryDoc['category_name']);
                          }).toList(),
                        ),
                      ),
                      Container(
                        height: isMobile ? 300 : 450,
                        child: TabBarView(
                          children: categories.map((categoryDoc) {
                            final categoryName = categoryDoc['category_name'];
                            return _buildProductsSection(
                                context, categoryName, isMobile);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Text(
                            isDonateMode
                                ? 'The minimum donation amount is ₱100 worth of recyclables'
                                : 'Minimum booking amount: ₱${minimumBookingAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 5),
                          ValueListenableBuilder<double>(
                            valueListenable: _totalEstimatedProfit,
                            builder: (context, totalProfit, child) {
                              return Text(
                                isDonateMode
                                    ? 'Total Estimated Donation: ₱${totalProfit.toStringAsFixed(2)}'
                                    : 'Total Estimated Profit: ₱${totalProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: totalProfit >=
                                          (isDonateMode
                                              ? 100.0
                                              : minimumBookingAmount)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                  context); // Navigate back to the previous screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .grey, // Set the background color for Back button
                              padding: isMobile
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                            ),
                            child: const Text('Back',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              double minimumAmount =
                                  isDonateMode ? 100.0 : minimumBookingAmount;
                              if (_totalEstimatedProfit.value < minimumAmount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please add more recyclables to reach the minimum amount of ₱${minimumAmount.toStringAsFixed(0)}.'),
                                  ),
                                );
                                return;
                              }

                              if (_selectedArea == null ||
                                  _selectedArea!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select a district to proceed.')),
                                );
                                return;
                              }

                              Map<String, dynamic> selectedItems = {};
                              _productQuantities
                                  .forEach((productName, notifier) {
                                if (notifier.value > 0) {
                                  final productPrice =
                                      _productPrices[productName];
                                  final priceTimestamp =
                                      _productTimestamps[productName];
                                  final productDescription =
                                      _productDescriptions[productName];
                                  final productImage =
                                      _productImages[productName];
                                  final productCategory =
                                      _productCategories[productName];
                                  final productId = _productIds[productName];
                                  final originalPrice =
                                      _originalPrices[productName];

                                  selectedItems[productName] = {
                                    'weight': notifier.value,
                                    'price_per_kg': productPrice,
                                    'original_price': originalPrice,
                                    'total_price':
                                        notifier.value * productPrice!,
                                    'price_timestamp': priceTimestamp,
                                    'description': productDescription,
                                    'image': productImage,
                                    'category': productCategory,
                                    'product_Id': productId,
                                    'district': _selectedArea,
                                  };
                                }
                              });

                              if (selectedItems.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select at least one item.')),
                                );
                                return;
                              }

                              final address = _defaultAddressController.text;
                              final landmark = _landmarkController.text;
                              final contact = _contactController.text;
                              final fullAddress =
                                  '$address, Landmark: $landmark';

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
                                    'area': _selectedArea?.toLowerCase(),
                                  });
                                } catch (e) {
                                  print('Error updating Firestore: $e');
                                }
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPreviewScreen(
                                    selectedItems: selectedItems,
                                    address: fullAddress,
                                    contact: contact,
                                    landmark: landmark,
                                    district: _selectedArea!,
                                    mode: isDonateMode ? 'donate' : 'sell',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[
                                  700], // Set the background color for Next button
                              padding: isMobile
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                            ),
                            child: const Text('Next',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
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

// Helper function to get only categories with products
  Future<List<DocumentSnapshot>> _getCategoriesWithProducts() async {
    final categorySnapshot =
        await FirebaseFirestore.instance.collection('category').get();
    final categoriesWithProducts = <DocumentSnapshot>[];

    for (var categoryDoc in categorySnapshot.docs) {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: categoryDoc['category_name'])
          .limit(1)
          .get();

      // Only add categories that have at least one product
      if (productsSnapshot.docs.isNotEmpty) {
        categoriesWithProducts.add(categoryDoc);
      }
    }

    return categoriesWithProducts;
  }

  Widget _buildProductsSection(
      BuildContext context, String category, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading products');
        final products = snapshot.data?.docs ?? [];
        if (products.isEmpty)
          return const Text('No products available in this category.');

        return SingleChildScrollView(
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: products.map((productDoc) {
              final productData = productDoc.data() as Map<String, dynamic>;
              final productName = productData['product_name'].toUpperCase();
              final productDescription = productData['details'];
              final productImageFile = productData['picture'];
              final productCategory = productData['category'];
              final productId = productDoc.id;

              _productCategories[productName] = productCategory;
              _productIds[productName] = productId;

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
                      priceSnapshot.data!.docs.isEmpty)
                    return const Text('Price unavailable');

                  final priceData = priceSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                  final productPrice = priceData['price'] as double;
                  final originalPrice = priceData['original_price']
                      as double; // fetch original price
                  final priceTimestamp = priceData['time'] as Timestamp;

                  _productQuantities.putIfAbsent(
                      productName, () => ValueNotifier<double>(0));
                  _productPrices.putIfAbsent(productName, () => productPrice);
                  _originalPrices.putIfAbsent(productName, () => originalPrice);
                  _productTimestamps.putIfAbsent(
                      productName, () => priceTimestamp);
                  _productDescriptions.putIfAbsent(
                      productName, () => productDescription);
                  _productImages.putIfAbsent(
                      productName, () => productImageFile);

                  return _buildProductCard(
                    context,
                    productName,
                    productDescription,
                    productPrice,
                    originalPrice, // pass original price to card
                    productImageFile,
                    priceTimestamp,
                    productCategory,
                    productId,
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

  Widget _buildProductCard(
    BuildContext context,
    String title,
    String description,
    double pricePerKg,
    double originalPrice,
    String imageFileName,
    Timestamp priceTimestamp,
    String category,
    String documentId,
    bool isMobile,
  ) {
    // Initialize the controller with the current value from the ValueNotifier
    final weightController = TextEditingController();
    weightController.text = _productQuantities[title]?.value.toString() ?? '0';

    return SizedBox(
      width: isMobile
          ? MediaQuery.of(context).size.width * 0.9
          : (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: isMobile
              ? const EdgeInsets.all(10.0)
              : const EdgeInsets.all(20.0),
          child: Column(
            children: [
              FutureBuilder<String>(
                future: _fetchImageFromFirebaseStorage(imageFileName),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Text('Error loading image');
                  if (!snapshot.hasData)
                    return const Text('Image not available');

                  final imageUrl = snapshot.data!;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              _truncateDescription(description,
                                  isMobile ? 15 : 20), // 10 words for mobile
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isMobile)
                              Text(
                                '₱ ${pricePerKg.toStringAsFixed(2)} / kg',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
              Divider(thickness: 1, color: Colors.green[100]),
              ValueListenableBuilder<double>(
                valueListenable: _productQuantities[title]!,
                builder: (context, weight, child) {
                  // Update the controller's text whenever the weight changes
                  weightController.value = TextEditingValue(
                    text: weight.toString(),
                    selection: TextSelection.fromPosition(
                      TextPosition(offset: weight.toString().length),
                    ),
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter weight:',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                height: 40,
                                width: 100,
                                child: TextField(
                                  controller: weightController,
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    double newWeight =
                                        0.0; // Default to 0 if input is empty or invalid
                                    if (value.isNotEmpty) {
                                      newWeight = double.tryParse(value) ?? 0.0;
                                    }

                                    // Ensure the value has at most 2 decimal places
                                    newWeight = double.parse(
                                        newWeight.toStringAsFixed(2));

                                    // Update the ValueNotifier with the new weight
                                    _productQuantities[title]!.value =
                                        newWeight;

                                    // Update the total estimated profit
                                    _updateTotalEstimatedProfit();
                                  },
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "kg",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isDonateMode)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Estimated Profit',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            Text(
                              '₱ ${(pricePerKg * weight).toStringAsFixed(2)}',
                              style: TextStyle(
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

  Widget _buildAddressSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2)),
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  // Move camera to user's saved position if available
                  if (currentPosition != null) {
                    mapController?.animateCamera(
                        CameraUpdate.newLatLng(currentPosition!));
                  }
                },
                initialCameraPosition: _cameraPosition,
                markers: _markers,
                onTap: (LatLng position) async {
                  setState(() {
                    currentPosition = position;
                  });

                  // Fetch the address for the tapped location
                  await _getAddressFromLatLng(position);

                  // Add the marker on the new position and update the text field
                  _addMarker(position, currentAddress ?? 'Selected Location');
                  _defaultAddressController.text = currentAddress ??
                      ''; // Explicitly update the TextEditingController
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildAddressFields(),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                height: 450,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2)),
                child: GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    // Move camera to user's saved position if available
                    if (currentPosition != null) {
                      mapController?.animateCamera(
                          CameraUpdate.newLatLng(currentPosition!));
                    }
                  },
                  initialCameraPosition: _cameraPosition,
                  markers: _markers,
                  onTap: (LatLng position) async {
                    setState(() {
                      currentPosition = position;
                    });

                    // Fetch the address for the tapped location
                    await _getAddressFromLatLng(position);

                    // Add the marker on the new position and update the text field
                    _addMarker(position, currentAddress ?? 'Selected Location');
                    _defaultAddressController.text = currentAddress ??
                        ''; // Explicitly update the TextEditingController
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
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
            'Default Address (Please click on the map your exact location)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _defaultAddressController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: 'Enter default address'),
          onSubmitted: (value) {
            _getLatLngFromAddress(value);
          },
        ),
        const SizedBox(height: 20),
        const Text('House no., Landmark, etc.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _landmarkController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter landmark or house no.'),
        ),
        const SizedBox(height: 20),
        const Text('District',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedArea,
          items: _areas
              .map((area) => DropdownMenuItem(value: area, child: Text(area)))
              .toList(),
          onChanged: (value) => setState(() => _selectedArea = value),
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: 'Select District'),
        ),
        const SizedBox(height: 20),
        const Text('Phone Number',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _contactController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: 'Enter phone number'),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign
                  .center, // Ensures text is centered within its container
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Trashure - Login Required',
            style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You need to be logged in to proceed.',
                style: TextStyle(fontSize: 18, color: Colors.black),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: const Text('Login Now',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
