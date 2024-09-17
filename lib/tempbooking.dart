import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.jpg'),
        ),
        title: Text(
          'Trashure',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          _buildAppBarItem(context, 'Home'),
          _buildAppBarItem(context, 'Book'),
          _buildAppBarItem(context, 'Pricing'),
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Error loading user data',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final userName =
                    userData != null && userData.containsKey('name')
                        ? userData['name']
                        : 'User';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoURL ??
                            'https://via.placeholder.com/150'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.green[700]),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                ),
                child: const Row(
                  children: [
                    Text('Login Now'),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
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
              onPressed: () {
                Navigator.pushNamed(context, '/Address');
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

  Widget _buildAppBarItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () {
          if (title == 'Home') {
            Navigator.pushNamed(context, '/');
          } else if (title == 'Book') {
          } else if (title == 'Pricing') {
            Navigator.pushNamed(context, '/Pricing');
          }
        },
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
          ),
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
                final productName = productData['product_name'];
                final productDescription = productData['details'];
                final productPrice = productData['price'] as double;
                final productImage = productData['picture'];

                // Initialize quantity for each product if not set
                _productQuantities.putIfAbsent(
                    productName, () => ValueNotifier<int>(0));

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
                      // TextField to input the quantity
                      SizedBox(
                        width: 50,
                        height: 40,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // Update the quantity value when the text changes
                            int? newQuantity = int.tryParse(value);
                            if (newQuantity != null) {
                              _productQuantities[title]!.value = newQuantity;
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
                        '₱ ${(pricePerKg * quantity).toStringAsFixed(1)}',
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
