import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';

class SustainabilityAwarenessPage extends StatefulWidget {
  @override
  _SustainabilityAwarenessPageState createState() =>
      _SustainabilityAwarenessPageState();
}

class _SustainabilityAwarenessPageState
    extends State<SustainabilityAwarenessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),

            // Problem with Waste (Green Background with Image)
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 16.0), // Adds left and right margin
              padding:
                  EdgeInsets.all(16.0), // Adds padding inside the container
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(25.0), // Rounded border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A. The Problem with Waste',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Image for the section
                  Container(
                    height: 450.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      image: DecorationImage(
                        image: AssetImage('assets/images/garbagedump.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Globally, the world generates over 2 billion tons of waste annually, and only about 13.5% of it gets recycled. "
                    "Over 8 million tons of plastic waste enter the oceans every year, endangering marine life and disrupting ecosystems. \n \n"
                    "In the Philippines, over 40,000 tons of waste are generated daily, with around 20% ending up in bodies of water. "
                    "Improper waste disposal leads to pollution, harm to wildlife, and increased health risks. If current trends continue, global waste generation is expected to reach 3.40 billion tons in about 30 years—a 70% increase.",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Impact of Improper Disposal:\n",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  Wrap(
                    spacing: 10, // Horizontal spacing between cards
                    runSpacing: 10, // Vertical spacing between rows
                    alignment: WrapAlignment
                        .start, // Aligns all children to the start (left)
                    children: [
                      // Pollution Card
                      SizedBox(
                        width: 350, // Give a consistent width to each card
                        child: _buildInfoCard(
                          title: "Pollution",
                          description:
                              "Chemicals from waste contaminate soil and water.\n",
                          image: 'assets/images/pollution.jpg',
                        ),
                      ),
                      // Wildlife Harm Card
                      SizedBox(
                        width: 350,
                        child: _buildInfoCard(
                          title: "Wildlife Harm",
                          description:
                              "Animals ingest plastic, mistaking it for food.\n",
                          image: 'assets/images/turtleingest.jpg',
                        ),
                      ),
                      // Health Risks Card
                      SizedBox(
                        width: 350,
                        child: _buildInfoCard(
                          title: "Health Risks",
                          description:
                              "Uncollected waste becomes a breeding ground for pests and diseases.\n",
                          image: 'assets/images/rats.jpg',
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 20),

            // Why Recycling is Important (White Background with Image)
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'B. Why Recycling is Important',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800], // Dark green for the title
                    ),
                  ),
                  SizedBox(height: 10),
                  // Image for the section
                  Container(
                    height: 500.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      image: DecorationImage(
                        image: AssetImage('assets/images/recycle.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Recycling plays a crucial role in protecting the environment, conserving natural resources, and reducing pollution. Here are some key reasons why recycling is important:",
                    style: TextStyle(
                      fontSize: 20,
                      color:
                          Colors.green[800], // Dark green for the main content
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "• Conserves Natural Resources: Recycling reduces the need for raw materials, preserving forests, water, and minerals.\n"
                    "• Saves Energy: Producing goods from recycled materials uses significantly less energy compared to new materials.\n"
                    "• Reduces Pollution: Recycling helps reduce air and water pollution by minimizing waste sent to landfills and incinerators.\n"
                    "• Economic Benefits: Recycling industries create jobs and support the economy by providing raw materials for new products.\n"
                    "• Mitigates Climate Change: Recycling reduces greenhouse gas emissions by lowering the energy required for manufacturing.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors
                          .green[700], // Slightly lighter green for subcontent
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),

            // Step-by-Step Guide on Waste Segregation (Enhanced Information Section)
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[600],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction Section: Why Segregate Waste?
                  Text(
                    'C. Enhanced Simple Guide to Waste Segregation',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: "Why Segregate Your Waste?\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                18, // Optional: Increase font size for emphasis
                          ),
                        ),
                        TextSpan(
                          text:
                              "Waste segregation is the process of separating waste into different categories to make it easier to recycle and dispose of properly. It has many benefits:\n"
                              "• Protects the Environment: Proper segregation reduces the amount of waste sent to landfills and prevents pollution.\n"
                              "• Conserves Resources: Recycling non-biodegradable waste helps save natural resources like trees, water, and energy.\n"
                              "• Reduces Pollution: Sorting waste reduces the risk of harmful chemicals leaching into the soil and water.\n"
                              "• Helps You Earn: By properly segregating your waste, you can sell your recyclable items to Trashure, making a positive impact while earning money.",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Biodegradable Waste Section
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Biodegradable Waste",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          height: 400.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            image: DecorationImage(
                              image:
                                  AssetImage('assets/images/biodegradable.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Biodegradable waste includes all organic materials that can naturally break down. This waste can be composted to create nutrient-rich soil, reducing the amount of waste sent to landfills.",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "How to Segregate:\n"
                          "• Use a separate bin for all organic waste.\n"
                          "• Line the bin with newspaper or a compostable bag for easy cleanup.\n"
                          "• Do not mix biodegradable waste with plastic, metal, or glass items.",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Non-Biodegradable & Recyclable Waste Section
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Non-Biodegradable & Recyclable Waste",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          height: 400.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            image: DecorationImage(
                              image:
                                  AssetImage('assets/images/segregation.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Non-biodegradable waste consists of materials that do not decompose easily, such as plastics and metals. Many of these items are recyclable and can be repurposed into new products.",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "How to Segregate:\n"
                          "• Use a separate bin for plastics, metals, paper, and glass.\n"
                          "• Rinse all containers to remove food residue before placing them in the bin.\n"
                          "• Flatten cardboard boxes and plastic bottles to save space.",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Best Practices Section
                  Text(
                    "Best Practices for Effective Waste Segregation:\n"
                    "• Label Your Bins Clearly: Use color-coded bins (Green for Biodegradable, Blue for Non-Biodegradable & Recyclable) to make it easy for everyone to sort waste correctly.\n"
                    "• Educate Your Household: Ensure everyone knows how to properly segregate waste to avoid mistakes.\n"
                    "• Dispose of Waste Regularly: Take out your sorted waste regularly to maintain cleanliness and prevent odors.",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Common Mistakes Section
                  Text(
                    "Common Mistakes to Avoid:\n"
                    "• Mixing Waste Types: Do not mix food waste with recyclables like plastic or metal.\n"
                    "• Skipping Rinsing: Always rinse containers to prevent contamination of recyclable items.\n"
                    "• Including Hazardous Waste: Keep hazardous materials like batteries, chemicals, and electronics separate for special disposal.",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Recycling Tips Section (White Background)
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Text(
                    "D. Simple Recycling Tips",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 10),

                  // Tip 1: Rinse and Clean Containers
                  Text(
                    "1. Rinse and Clean Containers:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Always rinse food containers like cans, bottles, and plastic containers before placing them in the recycling bin. Food residue can contaminate recyclables, making them harder to process.",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                  SizedBox(height: 10),

                  // Tip 2: Avoid Contaminated Items
                  Text(
                    "2. Avoid Recycling Contaminated Items:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Greasy pizza boxes, used paper plates, and food-stained napkins are not recyclable. These items should go in the compost or general waste bin.",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                  SizedBox(height: 10),

                  // Tip 3: Check the Pricing Tab
                  Text(
                    "3. Check the Pricing Tab for Recyclable Items:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Refer to the Pricing Tab in the app to see a detailed list of items that can be recycled and the corresponding prices. This helps you sort your waste correctly and know which items can be sold to Trashure.",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                  SizedBox(height: 10),

                  // Tip 4: Segregate Properly
                  Text(
                    "4. Segregate Your Waste Properly:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Separate your waste into two main categories: Biodegradable (food scraps, yard waste) and Non-Biodegradable & Recyclables (plastics, metals, paper).",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                  SizedBox(height: 10),

                  // Tip 5: Know What Can’t Be Recycled
                  Text(
                    "5. Know What Can’t Be Recycled:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Some common items that cannot be recycled include plastic straws, Styrofoam, wax-coated paper cups, and plastic utensils. These items should go in the general waste bin.",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                  SizedBox(height: 10),

                  // Tip 6: Spread the Word
                  Text(
                    "6. Spread the Word:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Share your recycling habits with friends and family. The more people know how to recycle correctly, the bigger the impact on reducing waste and conserving resources.",
                    style: TextStyle(fontSize: 17, color: Colors.green[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    EdgeInsets.all(16.0), // Adds padding inside the container
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Turn Trash into Treasure. Save the World with Trashure.",
                      style: TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    _buildBookNowButton(context),
                  ],
                ),
              ),
            ),
            // Book Now Button
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required String image,
  }) {
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 300.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              image: DecorationImage(
                image: AssetImage('$image'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Column(
        children: [
          Text(
            'Recycling Saves Our Planet',
            style: TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          // Display the planet.jpg image with the same size as the placeholder
          Container(
            height: 500.0,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/recycling.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redirecting to booking page...'),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Book Now',
        style: TextStyle(
          fontSize: 20,
          color: Colors.green,
        ),
      ),
    );
  }
}
