import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering Markdown
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/footer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBanner(context), // Existing banner
                  const SizedBox(height: 20),
                  _buildStepByStepGuide(
                      context), // Updated interactive step-by-step guide
                  const SizedBox(height: 40),
                  _buildMaterialTypesSection(
                      context), // Updated section for materials
                  const SizedBox(height: 40),
                  Divider(
                    color: Colors.grey[
                        400], // Divider color to separate the body from the Footer
                    thickness: 1,
                    height: 1,
                  ),
                  const Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/landing.jpg', // Replace with your image path
          width: double.infinity,
          height:
              MediaQuery.of(context).size.height * 0.4, // Use relative height
          fit: BoxFit.cover,
        ),
        // Gradient overlay to add a green tint
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
        // Text Overlay
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
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
                      fontSize: 24, // Reduce font size for smaller screens
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sell your segregated trash and earn money.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, // Adjust font size
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Together, we can create a cleaner, greener planet!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, // Adjust font size
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
                      backgroundColor: Colors.white, // Button background color
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Sell Your Trash Now',
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
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align items to the start
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

  Widget _buildMaterialTypesSection(BuildContext context) {
    return Column(
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
        _buildMaterialTabs(context),
      ],
    );
  }

  Widget _buildMaterialTabs(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs: Plastic, Metal, Glass
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: 'Plastic'),
              Tab(text: 'Metal'),
              Tab(text: 'Glass'),
            ],
          ),
          SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.5, // Use relative height
            child: TabBarView(
              children: [
                _buildPlasticTypesGrid(context),
                _buildMetalTypesGrid(context),
                _buildGlassTypesGrid(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlasticTypesGrid(BuildContext context) {
    final plasticTypes = [
      {
        'title': 'PET (Polyethylene Terephthalate)',
        'icon': Icons.local_drink,
        'tip': 'Used in water bottles, clear with a "1" symbol.',
        'examples': [
          'assets/images/plastic_pet.png'
        ], // Replace with your image paths
      },
      {
        'title': 'HDPE (High-Density Polyethylene)',
        'icon': Icons.shopping_bag,
        'tip': 'Found in milk jugs, white/opaque with a "2" symbol.',
        'examples': ['assets/images/plastic_hdpe.png'],
      },
      {
        'title': 'PVC (Polyvinyl Chloride)',
        'icon': Icons.plumbing,
        'tip': 'Used in plumbing pipes, marked with a "3" symbol.',
        'examples': ['assets/images/plastic_pvc.png'],
      },
      {
        'title': 'LDPE (Low-Density Polyethylene)',
        'icon': Icons.wrap_text,
        'tip': 'Found in plastic wraps, has a "4" symbol.',
        'examples': ['assets/images/plastic_ldpe.png'],
      },
      {
        'title': 'PP (Polypropylene)',
        'icon': Icons.kitchen,
        'tip': 'Common in yogurt containers, marked with a "5" symbol.',
        'examples': ['assets/images/plastic_pp.png'],
      },
      {
        'title': 'PS (Polystyrene)',
        'icon': Icons.fastfood,
        'tip': 'Used in Styrofoam, comes with a "6" symbol.',
        'examples': ['assets/images/plastic_ps.png'],
      },
    ];

    // Calculate grid column count based on screen width
    int gridCount = MediaQuery.of(context).size.width > 600 ? 4 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: plasticTypes.length,
      shrinkWrap: true, // Prevents GridView from taking infinite height
      physics:
          const NeverScrollableScrollPhysics(), // Prevent internal scrolling
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount, // Responsive grid column count
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Adjusted aspect ratio
      ),
      itemBuilder: (context, index) {
        final plastic = plasticTypes[index];
        return GestureDetector(
          onTap: () {
            // Show details page or dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaterialDetailsPage(
                  title: plastic['title'] as String,
                  description: plastic['tip'] as String,
                  examples: plastic['examples'] as List<String>,
                ),
              ),
            );
          },
          child: Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    plastic['icon'] as IconData,
                    size: 36,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plastic['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    plastic['tip'] as String,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetalTypesGrid(BuildContext context) {
    final metalTypes = [
      {
        'title': 'Aluminum',
        'icon': Icons.coffee,
        'tip': 'Used in beverage cans and foil.',
        'examples': ['assets/images/metal_aluminum.png'],
      },
      {
        'title': 'Steel',
        'icon': Icons.build,
        'tip': 'Found in food cans and some appliance parts.',
        'examples': ['assets/images/metal_steel.png'],
      },
      // Add more metal types as needed
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: metalTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Adjusted to 2
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final metal = metalTypes[index];
        return GestureDetector(
          onTap: () {
            // Show details page or dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaterialDetailsPage(
                  title: metal['title'] as String,
                  description: metal['tip'] as String,
                  examples: metal['examples'] as List<String>,
                ),
              ),
            );
          },
          child: Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    metal['icon'] as IconData,
                    size: 36,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    metal['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    metal['tip'] as String,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassTypesGrid(BuildContext context) {
    final glassTypes = [
      {
        'title': 'Clear Glass',
        'icon': Icons.local_bar,
        'tip': 'Used in beverage bottles and jars.',
        'examples': ['assets/images/glass_clear.png'],
      },
      {
        'title': 'Colored Glass',
        'icon': Icons.wine_bar,
        'tip': 'Includes green and brown glass bottles.',
        'examples': ['assets/images/glass_colored.png'],
      },
      // Add more glass types as needed
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: glassTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Adjusted to 2
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final glass = glassTypes[index];
        return GestureDetector(
          onTap: () {
            // Show details page or dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaterialDetailsPage(
                  title: glass['title'] as String,
                  description: glass['tip'] as String,
                  examples: glass['examples'] as List<String>,
                ),
              ),
            );
          },
          child: Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    glass['icon'] as IconData,
                    size: 36,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    glass['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    glass['tip'] as String,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MaterialDetailsPage extends StatelessWidget {
  final String title;
  final String description;
  final List<String> examples;

  const MaterialDetailsPage({
    Key? key,
    required this.title,
    required this.description,
    required this.examples,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green, // Adjust the color as needed
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    examples[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
