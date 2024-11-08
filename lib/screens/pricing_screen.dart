import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the time
import 'package:trashure/components/appbar.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  _PricingScreenState createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Define the threshold for mobile view

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildCategorySection(context, 'PLASTICS', 'plastics', isMobile),
              const SizedBox(height: 40),
              _buildCategorySection(context, 'METALS', 'metals', isMobile),
              const SizedBox(height: 40),
              _buildCategorySection(context, 'GLASS', 'glass', isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String title, String category, bool isMobile) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 24 : 32, // Adjust text size for mobile
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 10),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildProductTable(context, category),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      height: 3,
      color: Colors.green[100],
    );
  }

  // Build a table-like structure for displaying products
  Widget _buildProductTable(BuildContext context, String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error fetching products: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final products = snapshot.data!.docs;
        if (products.isEmpty) {
          return const Text('No products available in this category.');
        }

        return Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            // Table Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                _buildTableHeader('Product Name'),
                _buildTableHeader('Latest Price'),
                _buildTableHeader('Difference'),
                _buildTableHeader('Last Updated'),
              ],
            ),
            // Populate table rows with product data
            ...products
                .map((product) => _buildProductRow(context, product))
                .toList(),
          ],
        );
      },
    );
  }

  // Helper to build each product row in the table and make it clickable
  TableRow _buildProductRow(
      BuildContext context, QueryDocumentSnapshot productDoc) {
    final productData = productDoc.data() as Map<String, dynamic>;
    final productId = productDoc.id;
    final productName = productData['product_name'] ?? '';

    return TableRow(
      children: [
        _buildProductCell(context, productId, productName, productName),
        _buildProductCell(context, productId, productName,
            _buildLatestPriceCell(context, productId)),
        _buildProductCell(context, productId, productName,
            _buildPriceDifferenceCell(context, productId)),
        _buildProductCell(context, productId, productName,
            _buildLastUpdatedCell(context, productId)),
      ],
    );
  }

  Widget _buildProductCell(BuildContext context, String productId,
      String productName, dynamic content) {
    return GestureDetector(
      onTap: () => _showProductDetails(context, productId, productName),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: content is String
            ? Text(content,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
            : content, 
      ),
    );
  }

  // Helper to build table header cells
  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper to fetch and display the latest price
  Widget _buildLatestPriceCell(BuildContext context, String productId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('prices')
          .orderBy('time', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text('N/A');
        }
        final priceData =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final latestPrice = priceData['price'] ?? 0.0;
        return Text('₱ ${latestPrice.toStringAsFixed(2)} / kg');
      },
    );
  }

  // Helper to fetch and display the price difference
  Widget _buildPriceDifferenceCell(BuildContext context, String productId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('prices')
          .orderBy('time', descending: true)
          .limit(2)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text('N/A');
        }
        final priceData = snapshot.data!.docs;
        final latestPrice = priceData[0]['price'] ?? 0.0;
        double previousPrice = latestPrice;
        if (priceData.length > 1) {
          previousPrice = priceData[1]['price'] ?? latestPrice;
        }

        final difference = latestPrice - previousPrice;
        final priceDifference = difference > 0
            ? '+₱${difference.toStringAsFixed(2)}'
            : '-₱${difference.abs().toStringAsFixed(2)}';
        final differenceColor = difference > 0 ? Colors.green : Colors.red;

        return Text(
          priceDifference,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: differenceColor,
          ),
        );
      },
    );
  }

  // Helper to fetch and display the last updated time
  Widget _buildLastUpdatedCell(BuildContext context, String productId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('prices')
          .orderBy('time', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text('N/A');
        }
        final priceData =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final lastUpdated = priceData['time'] as Timestamp;
        final formattedTime =
            DateFormat('yyyy-MM-dd HH:mm').format(lastUpdated.toDate());

        return Text(formattedTime);
      },
    );
  }

  // Function to show the modal with last 5 updates of the selected product
  void _showProductDetails(
      BuildContext context, String productId, String productName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$productName - Price History',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .collection('prices')
                    .orderBy('time', descending: true)
                    .limit(10)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Text('No price history available.');
                  }

                  final priceHistory = snapshot.data!.docs;
                  return Column(
                    children: priceHistory.map((priceDoc) {
                      final priceData = priceDoc.data() as Map<String, dynamic>;
                      final price = priceData['price'] ?? 0.0;
                      final time = priceData['time'] as Timestamp;
                      final formattedPrice =
                          '₱ ${price.toStringAsFixed(2)} / kg';
                      final formattedTime =
                          DateFormat('yyyy-MM-dd HH:mm').format(time.toDate());

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formattedPrice,
                                style: const TextStyle(fontSize: 16)),
                            Text(formattedTime,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
