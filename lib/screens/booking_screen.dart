import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trashure/screens/address_screen.dart';
import 'package:trashure/screens/bookpreview_screen.dart';
import 'package:trashure/components/appbar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('PLASTICS'),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 10),
            _buildProductsSection(context, 'plastics', _showAllPlastics, () {
              setState(() {
                _showAllPlastics = !_showAllPlastics;
              });
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('METALS'),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 400,
              color: Colors.green[700],
            ),
            const SizedBox(height: 10),
            _buildProductsSection(context, 'metals', _showAllMetals, () {
              setState(() {
                _showAllMetals = !_showAllMetals;
              });
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Collect selected items, their quantities, prices, timestamps, and other details
                Map<String, dynamic> selectedItems = {};

                _productQuantities.forEach((productName, notifier) {
                  if (notifier.value > 0) {
                    final productPrice =
                        _productPrices[productName]; // Get the price
                    final priceTimestamp =
                        _productTimestamps[productName]; // Get the timestamp

                    // Access the product description and image from the stored maps
                    final productDescription =
                        _productDescriptions[productName];
                    final productImage = _productImages[productName];

                    selectedItems[productName] = {
                      'weight': notifier.value,
                      'price_per_kg': productPrice, // Store the price
                      'total_price': notifier.value *
                          productPrice!, // Calculate total price
                      'price_timestamp': priceTimestamp, // Store the timestamp
                      'description':
                          productDescription, // Store product description
                      'image': productImage, // Store product image
                    };
                  }
                });

                // Navigate to AddressScreen to get the user's address
                final address = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressScreen(),
                  ),
                );

                if (address != null) {
                  // Navigate to BookingPreviewScreen after getting the address
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPreviewScreen(
                        selectedItems: selectedItems,
                        address: address,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

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
                  );
                },
              ),
            ],
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
