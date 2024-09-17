import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trashure/address_screen.dart';
import 'package:trashure/bookpreview_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('PLASTICS'),
            _buildProductsSection(context, 'plastics', _showAllPlastics, () {
              setState(() {
                _showAllPlastics = !_showAllPlastics;
              });
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('METALS'),
            _buildProductsSection(context, 'metals', _showAllMetals, () {
              setState(() {
                _showAllMetals = !_showAllMetals;
              });
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hasSelectedItems()
                  ? () async {
                      // Collect selected items, their quantities, and prices
                      Map<String, dynamic> selectedItems = {};

                      _productQuantities.forEach((productName, notifier) {
                        if (notifier.value > 0) {
                          selectedItems[productName] = {
                            'quantity': notifier.value,
                            'price_per_kg': _productPrices[productName],
                            'total_price': notifier.value *
                                _productPrices[productName]!,
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
                    }
                  : () {
                      // Show alert dialog if no items are selected
                      _showAlertDialog(context, 'No items selected',
                          'Please select at least one recyclable item before proceeding.');
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

  // Check if any quantity is greater than zero
  bool _hasSelectedItems() {
    return _productQuantities.values.any((notifier) => notifier.value > 0);
  }

  // Show an alert dialog when no items are selected
  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
                final productName = productData['product_name'];
                final productDescription = productData['details'];
                final productPrice = productData['price'] as double;
                final productImage = productData['picture'];

                // Initialize quantity and price for each product if not set
                _productQuantities.putIfAbsent(
                    productName, () => ValueNotifier<int>(0));
                _productPrices.putIfAbsent(productName, () => productPrice);

                return _buildProductCard(
                  context,
                  productName,
                  productDescription,
                  productPrice,
                  productImage,
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
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 32,
            fontWeight: FontWeight.bold,
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
  ) {
    // Controller to manage the input for quantity
    TextEditingController quantityController = TextEditingController();

    // Initialize with the current quantity value
    quantityController.text = _productQuantities[title]!.value.toString();

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2, // Adjust width for two columns
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
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
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
                builder: (context, quantity, child) {
                  // Update the text field when the quantity changes
                  quantityController.text = quantity.toString();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.green[700]),
                        onPressed: () {
                          if (quantity > 0) {
                            _productQuantities[title]!.value -= 1;
                          }
                        },
                      ),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (newValue) {
                            final int? parsedQuantity =
                                int.tryParse(newValue);
                            if (parsedQuantity != null &&
                                parsedQuantity >= 0) {
                              _productQuantities[title]!.value =
                                  parsedQuantity;
                            }
                          },
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(0),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green[700]),
                        onPressed: () {
                          _productQuantities[title]!.value += 1;
                        },
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
    bool showAll,
    String seeMoreText,
    String seeLessText,
    VoidCallback onPressed,
  ) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        showAll ? seeLessText : seeMoreText,
        style: TextStyle(color: Colors.green[700]),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        Text(
          'TRASHURE © 2023. All rights reserved.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
