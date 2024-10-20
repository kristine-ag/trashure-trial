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
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildCategorySection(context, 'PLASTICS', 'plastics'),
              const SizedBox(height: 40),
              _buildCategorySection(context, 'METALS', 'metals'),
              const SizedBox(height: 40),
              _buildCategorySection(context, 'GLASS', 'glass'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, String category) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 10),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildProductCategory(context, category),
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

  Widget _buildProductCategory(BuildContext context, String category) {
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

        // Group cards in pairs of two for a row layout
        List<Widget> rows = [];
        for (int i = 0; i < products.length; i += 2) {
          // If there's only one item left, add an Expanded with an empty Container for the second column
          if (i + 1 < products.length) {
            rows.add(
              Row(
                children: [
                  Expanded(child: _buildProductCard(context, products[i])),
                  const SizedBox(width: 10), // Add some spacing between cards
                  Expanded(child: _buildProductCard(context, products[i + 1])),
                ],
              ),
            );
          } else {
            rows.add(
              Row(
                children: [
                  Expanded(child: _buildProductCard(context, products[i])),
                  const SizedBox(width: 10),
                  Expanded(child: Container()), // Empty container for balance
                ],
              ),
            );
          }
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, QueryDocumentSnapshot productDoc) {
    final productData = productDoc.data() as Map<String, dynamic>;
    final productId = productDoc.id;
    final productName = productData['product_name'] ?? '';
    final productDescription = productData['details'] ?? '';

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('prices')
          .orderBy('time', descending: true)
          .limit(5) // Fetch the last 5 price changes
          .get(),
      builder: (context, priceSnapshot) {
        if (priceSnapshot.hasError) {
          return Text('Error fetching price: ${priceSnapshot.error}');
        }
        if (priceSnapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (priceSnapshot.data == null || priceSnapshot.data!.docs.isEmpty) {
          return const Text('No price data available');
        }

        final prices = priceSnapshot.data!.docs;
        final latestPriceData = prices.first.data() as Map<String, dynamic>;
        final latestPrice = latestPriceData['price'] ?? 0.0;
        final latestTime = latestPriceData['time'] as Timestamp;

        // Format the latest price and time
        final latestPriceFormatted = '₱ ${latestPrice.toStringAsFixed(2)} / kg';
        final latestTimeFormatted = DateFormat('yyyy-MM-dd HH:mm').format(latestTime.toDate());

        // Get the previous price to calculate the difference
        double previousPrice = latestPrice;
        String priceDifference = '';
        Color differenceColor = Colors.black; // Default color for no change

        if (prices.length > 1) {
          final previousPriceData = prices[1].data() as Map<String, dynamic>;
          previousPrice = previousPriceData['price'] ?? latestPrice;

          final difference = latestPrice - previousPrice;
          priceDifference = difference > 0
              ? '+₱${difference.toStringAsFixed(2)}'
              : '-₱${difference.abs().toStringAsFixed(2)}';

          // Set color based on whether the difference is positive or negative
          differenceColor = difference > 0 ? Colors.green : Colors.red;
        }

        // Build the pricing card with price history and difference
        return _buildPricingCard(
          context,
          title: productName,
          subtitle: productDescription,
          price: latestPriceFormatted,
          lastUpdated: latestTimeFormatted,
          priceDifference: priceDifference,
          differenceColor: differenceColor,
          priceChanges: prices,
        );
      },
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required String lastUpdated,
    required String priceDifference,
    required Color differenceColor,
    required List<QueryDocumentSnapshot> priceChanges,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Difference: ',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  priceDifference,
                  style: TextStyle(
                    fontSize: 16,
                    color: differenceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: $lastUpdated',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Price History (Last 5 Changes):',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceHistory(priceChanges),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display the history of the last 5 price changes
  Widget _buildPriceHistory(List<QueryDocumentSnapshot> priceChanges) {
    return Column(
      children: priceChanges.map((priceDoc) {
        final priceData = priceDoc.data() as Map<String, dynamic>;
        final price = priceData['price'] ?? 0.0;
        final time = priceData['time'] as Timestamp;
        final formattedPrice = '₱ ${price.toStringAsFixed(2)} / kg';
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(time.toDate());

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedPrice,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
