import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBanner(context),  // Existing banner
            // const SizedBox(height: 20),
            // _buildGoalSection(context),
            const SizedBox(height: 40),
            _buildPlasticTypesSection(context),  // New Section for differentiating plastics
            const SizedBox(height: 40),
            Divider(
              color: Colors.grey[400], // Divider color to separate the body from the Footer
              thickness: 1,
              height: 1,
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/landing.jpg', // Replace with your image path
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 1, // Adjust the height as needed
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sell your segregated trash and earn money.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Together, we can create a cleaner, greener planet!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/Book');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green, backgroundColor: Colors.white, // text color
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

  // Widget _buildGoalSection(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 64.0),
  //     child: Column(
  //       children: [
  //         const Text(
  //           'HELP US REACH',
  //           style: TextStyle(
  //             color: Colors.green,
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const Text(
  //           'OUR GOAL!',
  //           style: TextStyle(
  //             color: Colors.orange,
  //             fontSize: 28,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         Container(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             children: [
  //               const Text(
  //                 'OUR MONTHLY GOAL',
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               _buildProgressBar(1000.0, 800.0, 'Mar'),
  //               _buildProgressBar(1000.0, 700.0, 'Feb'),
  //               _buildProgressBar(1000.0, 1000.0, 'Jan'),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProgressBar(double goal, double progress, String month) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress / goal,
          backgroundColor: Colors.green[100],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPlasticTypesSection(BuildContext context) {
    final plasticTypes = [
      {
        'title': 'PET (Polyethylene Terephthalate)',
        'icon': Icons.local_drink,
        'tip': 'Used in water bottles, clear with a "1" symbol.',
      },
      {
        'title': 'HDPE (High-Density Polyethylene)',
        'icon': Icons.shopping_bag,
        'tip': 'Found in milk jugs, white/opaque with a "2" symbol.',
      },
      {
        'title': 'PVC (Polyvinyl Chloride)',
        'icon': Icons.plumbing,
        'tip': 'Used in plumbing pipes, marked with a "3" symbol.',
      },
      {
        'title': 'LDPE (Low-Density Polyethylene)',
        'icon': Icons.wrap_text,
        'tip': 'Found in plastic wraps, has a "4" symbol.',
      },
      {
        'title': 'PP (Polypropylene)',
        'icon': Icons.kitchen,
        'tip': 'Common in yogurt containers, marked with a "5" symbol.',
      },
      {
        'title': 'PS (Polystyrene)',
        'icon': Icons.fastfood,
        'tip': 'Used in Styrofoam, comes with a "6" symbol.',
      },
    ];

    return Column(
      children: [
        const Text(
          'PLASTIC TYPES AND DIFFERENTIATION',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 40,
              childAspectRatio: 1,
            ),
            itemCount: plasticTypes.length,
            itemBuilder: (context, index) {
              final plastic = plasticTypes[index];
              return Card(
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
              );
            },
          ),
        ),
      ],
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
