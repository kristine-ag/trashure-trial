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
        return Column(
          children: products.map((productDoc) {
            final productData = productDoc.data() as Map<String, dynamic>;
            final productId = productDoc.id;
            final productName = productData['product_name'] ?? '';
            final productDescription = productData['details'] ?? '';
            final productImage = productData['picture'] as String?;
            final List<String> productImages = productImage != null ? [productImage] : <String>[];

            // Fetch both the latest and previous price to calculate the difference
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .collection('prices')
                  .orderBy('time', descending: true)
                  .limit(2) // Fetch the latest and previous prices
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

                final latestPriceData = priceSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                final latestPrice = latestPriceData['price'] ?? 0.0;
                final latestTime = latestPriceData['time'] as Timestamp;

                // Format the latest price and time
                final latestPriceFormatted = '₱ ${latestPrice.toStringAsFixed(2)} / kg';
                final latestTimeFormatted = DateFormat('yyyy-MM-dd HH:mm').format(latestTime.toDate());

                // Get the previous price (if available) and calculate the price change
                double previousPrice = latestPrice;
                String priceChange = '';
                String priceChangePercentage = '';
                if (priceSnapshot.data!.docs.length > 1) {
                  final previousPriceData = priceSnapshot.data!.docs[1].data() as Map<String, dynamic>;
                  previousPrice = previousPriceData['price'] ?? latestPrice;
                  final priceDifference = latestPrice - previousPrice;
                  final percentageChange = (priceDifference / previousPrice) * 100;

                  priceChange = priceDifference > 0
                      ? '+₱ ${priceDifference.toStringAsFixed(2)}'
                      : '-₱ ${priceDifference.abs().toStringAsFixed(2)}';

                  priceChangePercentage = percentageChange > 0
                      ? '+${percentageChange.toStringAsFixed(2)}%'
                      : '${percentageChange.toStringAsFixed(2)}%';
                }

                // Build the pricing card
                return _buildPricingCard(
                  context,
                  title: productName,
                  subtitle: productDescription,
                  price: latestPriceFormatted,
                  priceChange: priceChange,
                  priceChangePercentage: priceChangePercentage,
                  lastUpdated: latestTimeFormatted,
                  images: productImages,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required String priceChange,
    required String priceChangePercentage,
    required String lastUpdated,
    required List<String> images,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Details
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
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
                    Text(
                      'Change: $priceChange ($priceChangePercentage)',
                      style: TextStyle(
                        fontSize: 16,
                        color: priceChange.startsWith('+') ? Colors.green : Colors.red,
                      ),
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
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Image
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          images[0],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Text('No Image')),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
