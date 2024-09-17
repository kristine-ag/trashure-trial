import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              'BOOKING CONFIRMED',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 4,
              width: 350,
              color: Colors.green[700],
            ),
            const SizedBox(height: 60),
            const Icon(
              Icons.check_circle,
              size: 150,
              color: Colors.green,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate back to home or previous screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'RETURN HOME',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 80),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterColumn('Our Scope', ['Sample District 1', 'Sample District 2', 'ample District 3']),
          _buildFooterColumn('Our Partners', ['Lalala Inc.', 'Trash r Us', 'SM Cares', 'Eyyy Corp.']),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
