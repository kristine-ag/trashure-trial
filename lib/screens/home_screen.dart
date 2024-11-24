// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/ban_user.dart';
import 'package:trashure/components/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Marker> _warehouseMarkers = [];
  bool _isInteractingWithMap = false;
  bool _isBanned = false;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _checkUserReports();
    _fetchWarehouseLocations();
  }

  Future<void> _fetchWarehouseLocations() async {
    final CollectionReference branchCollection =
        FirebaseFirestore.instance.collection('branch');

    final QuerySnapshot snapshot = await branchCollection.get();
    final markers = snapshot.docs.map((doc) {
      GeoPoint geoPoint = doc['location'];
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(
          title: doc['area'] ?? 'Warehouse',
          snippet: doc['address'] ?? '',
        ),
      );
    }).toList();

    setState(() {
      _warehouseMarkers = markers;
    });
  }

  Future<void> _checkUserReports() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;

      // Fetch user's document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reports')
          .orderBy('datetimestamp', descending: true)
          .get();

      if (reportsSnapshot.docs.isEmpty) return;

      final reports = reportsSnapshot.docs.map((doc) {
        return {
          'datetimestamp': (doc['datetimestamp'] as Timestamp).toDate(),
          'reason': doc['reason'],
        };
      }).toList();

      setState(() {
        _reports = reports;
        _isBanned = reports.length >= 3;
      });

      // Check if 'review_status' field exists and is set to 'reported'
      final reviewStatus = userDoc.data()?['review_status'];
      if (reviewStatus == 'reported') {
        if (_isBanned) {
          _redirectToBanPage();
        } else if (reports.length == 1 || reports.length == 2) {
          _showWarning(reports.length, userId);
        }
      }

      // Fetch user's reports
    } catch (e) {
      print('Error checking user reports: $e');
    }
  }

  void _redirectToBanPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BanPage(reports: _reports),
        ),
      );
    });
  }

  void _showWarning(int reportCount, String userId) {
    final warningMessage = reportCount == 1
        ? 'You have 1 report. Please be cautious as 3 reports will lead to a temporary ban.'
        : 'You have 2 reports. Another report will result in a temporary ban.';

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text(warningMessage),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Change 'review_status' to 'understood'
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'review_status': 'understood'});

                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Understood',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBanWarningDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Under Review'),
          content: const Text(
              'Your account has been flagged for review due to reports against your account. Please proceed cautiously.'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Change 'review_status' to 'understood'
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'review_status': 'understood'});

                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Understood',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isBanned
        ? const SizedBox.shrink() // Prevent access to content if banned
        : Scaffold(
            appBar: CustomAppBar(),
            body: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification notification) {
                // Disable the glow effect at the edges of the scroll view
                notification.disallowIndicator();
                return true;
              },
              child: SingleChildScrollView(
                physics: _isInteractingWithMap
                    ? const NeverScrollableScrollPhysics() // Disable scrolling when interacting with map
                    : const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBanner(context),
                    const SizedBox(height: 20),
                    _buildDirectDeliverySection(context),
                    const SizedBox(height: 40),
                    _buildStepByStepGuide(context),
                    const SizedBox(height: 40),
                    _buildMaterialTypesSection(context),
                    const SizedBox(height: 40),
                    Divider(
                      color: Colors.grey[400],
                      thickness: 1,
                      height: 1,
                    ),
                    const Footer(),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildBanner(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/login.jpg',
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 1,
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.8),
                  Colors.transparent,
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Join the solution with Trashure:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sell your segregated trash and earn money.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Together, we can create a cleaner, greener planet!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/Book');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Sell/Donate Your Trash Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectDeliverySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direct Delivery to Warehouse',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Want to save on the ₱40 collection fee? Deliver your segregated recyclables directly to our warehouse and avoid the pickup cost. Find the nearest warehouse on the map below!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 350,
            child: GestureDetector(
              onPanDown: (_) => setState(() => _isInteractingWithMap = true),
              onPanCancel: () => setState(() => _isInteractingWithMap = false),
              onPanEnd: (_) => setState(() => _isInteractingWithMap = false),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(7.0676398240087766, 125.61457750980887),
                  zoom: 18,
                ),
                markers: Set.from(_warehouseMarkers),
                onMapCreated: (controller) {
                  // Additional setup if needed
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStepByStepGuide(BuildContext context) {
  final steps = [
    {
      'title': 'Step 1: Segregate Your Trash',
      'content': '''
Proper segregation of trash is essential for efficient recycling and disposal. Follow these guidelines to separate your waste:

### Biodegradable Waste

- Includes food scraps, garden waste, and other organic materials that decompose naturally.
- Place in a separate bag or bin labeled "Biodegradable."

### Non-biodegradable Waste/Recyclables

- Includes plastics, metals, glass, and other materials that do not decompose.
- Sort into categories:
  - **Plastic**: bottles, bags, containers.
  - **Glass**: bottles, jars (be sure to clean these before disposal).
  - **Metal**: cans, foil, aluminum.
  - **Paper**: newspapers, magazines, cardboard.
- Place each type of non-biodegradable waste into separate bags or bins to simplify collection.

### Hazardous Waste

- Includes batteries, light bulbs, and chemicals.
- These should be stored safely and disposed of properly through authorized disposal programs (not included in the regular collection service).
'''
    },
    {
      'title': 'Step 2: Booking a Collection Service',
      'content': '''
Once you’ve properly segregated your waste, you’re ready to book a collection service through the website. Here’s how it works:

### Measure Your Recyclables

- Use a weighing scale to measure the weight of your sorted recyclables (plastic, metal, glass, and paper). This step helps us estimate the value of your recyclables before collection.

### Select Recyclables and Their Weight

- On the website, choose the category of recyclables you have (e.g., plastic, metal, glass).
- Enter the weight for each category. The website will calculate the estimated value based on current market prices.

### Choose Your Location

- Input your address or choose from your saved locations. This helps us determine the nearest collection team for your area.

### Pick a Schedule

- Select a specific date and time for the collection service from the available options. We offer flexible scheduling to fit your convenience.

- Ensure your recyclables are packed and ready for pickup at the scheduled time.
'''
    },
    {
      'title': 'Step 3: Collection and Payment',
      'content': '''
On the scheduled date, our team will arrive at your location to collect your segregated trash.

They will verify the weight and quality of the recyclables, after which the payment is directly given to you upon verification of the amount of recyclable materials you provided.
'''
    },
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
      children: [
        const Text(
          'STEP BY STEP GUIDE ON HOW TO BOOK A COLLECTION SERVICE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16), // Add some spacing below the title
        Column(
          children: steps.map((step) {
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(
                step['title']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: step['content']!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16),
                      h2: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      h3: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Fetch products from Firestore and get image URLs from Firebase Storage
Future<List<Map<String, dynamic>>> _fetchProducts() async {
  final CollectionReference productsCollection =
      FirebaseFirestore.instance.collection('products');
  final QuerySnapshot snapshot = await productsCollection.get();

  List<Map<String, dynamic>> products = [];

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;

    // Fetch the image URL from Firebase Storage
    String pictureUrl = '';
    if (data['picture'] != null) {
      pictureUrl = await FirebaseStorage.instance
          .ref('product_images/${data['picture']}') // Use folder path
          .getDownloadURL();
    }

    products.add({
      'category': data['category'],
      'picture': pictureUrl, // Store the URL instead of the path
      'details': data['details'],
      'product_name': data['product_name'],
      'unit': data['unit'],
    });
  }

  return products;
}

Widget _buildMaterialTypesSection(BuildContext context) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _fetchProducts(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Error loading products'));
      }

      final products = snapshot.data ?? [];
      final categories = products.map((product) => product['category']).toSet();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'MATERIAL TYPES AND DIFFERENTIATION',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Explore the different recyclable materials we accept and learn more about how to prepare them for collection or direct delivery.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            DefaultTabController(
              length: categories.length,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      labelColor: Colors.green[700],
                      unselectedLabelColor: Colors.grey[600],
                      indicator: BoxDecoration(
                        color: Colors.green[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tabs: categories
                          .map((category) => Tab(text: category))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: TabBarView(
                      children: categories.map((category) {
                        final categoryProducts = products
                            .where((product) => product['category'] == category)
                            .toList();
                        return _buildProductsGrid(context, categoryProducts);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildProductsGrid(
    BuildContext context, List<Map<String, dynamic>> products) {
  int gridCount = MediaQuery.of(context).size.width > 600 ? 5 : 2;

  return GridView.builder(
    padding: const EdgeInsets.all(8.0),
    itemCount: products.length,
    physics: const ScrollPhysics(),
    shrinkWrap: true,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: gridCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.90,
    ),
    itemBuilder: (context, index) {
      final product = products[index];
      return GestureDetector(
        onTap: () {
          // Navigate to ProductDetailsPage with the product data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(
                title: product['product_name'],
                description: product['details'],
                picture: product['picture'],
                unit: product['unit'],
                category: product['category'],
              ),
            ),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8.0)),
                  child: product['picture'] != null
                      ? Image.network(
                          product['picture'],
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.grey,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['product_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product['unit']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ProductDetailsPage extends StatelessWidget {
  final String title;
  final String description;
  final String picture;
  final String unit;
  final String category;

  const ProductDetailsPage({
    required this.title,
    required this.description,
    required this.picture,
    required this.unit,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    double paddingValue = MediaQuery.of(context).size.width > 600 ? 50.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 500,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(picture, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Category: $category',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(
              'Unit: $unit',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
