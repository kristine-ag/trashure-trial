import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.jpg'), 
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPlasticsSection(context),
            SizedBox(height: 20),
            _buildFooter(context),
          ],
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
            Navigator.pushNamed(context, '/pricing');
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPlasticsSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'PLASTICS',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildPlasticCard(context, 'PET', 'Polyethylene Terephthalate', 7.5),
        _buildPlasticCard(context, 'HDPE', 'High Density Poly Ethylene', 8.0),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/Address');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
          ),
          child: Text(
            'Next',
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlasticCard(BuildContext context, String title, String description, double pricePerKg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5),
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
                      style: TextStyle(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: Colors.green[700]),
                    onPressed: () {
                      // Handle decrement
                    },
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        '1', // Quantity, should be dynamic
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green[700] ?? Colors.green),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.green[700]),
                    onPressed: () {
                      // Handle increment
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
                    '₱ ${pricePerKg.toStringAsFixed(1)}', 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          _buildFooterColumn('Our Scope', ['Sample District 1', 'Sample District 2', 'Sample District 3']),
          _buildFooterColumn('Our Partners', ['Lalala Inc.', 'Trash R Us', 'SM Cares']),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              item,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
