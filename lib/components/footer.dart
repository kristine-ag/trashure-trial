import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterColumn('Our Scope',
              ['District 1, Davao City, Philippines', 'District 2, Davao City, Philippines', 'District 3, Davao City, Philippines']),
          _buildFooterColumn('About Us', ['Our Story', 'Work with us']),
          _buildFooterColumn('Contact Us', ['kaagallawan@addu.edu.ph', 'anmlim@addu.edu.ph', '09076211492']),
        ],
      ),
    );
  }
}
