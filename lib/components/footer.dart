import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trashure/components/aboutus.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  Widget _buildFooterColumn(
      String title, List<String> items, {List<VoidCallback?>? actions}) {
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
        for (int i = 0; i < items.length; i++)
          GestureDetector(
            onTap: actions != null && actions.length > i ? actions[i] : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                items[i],
                style: TextStyle(
                  fontSize: 14,
                  color: actions != null && actions.length > i && actions[i] != null
                      ? Colors.blue
                      : Colors.black87,
                  decoration: actions != null && actions[i] != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showBusinessRegistrationModal(BuildContext context) {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController businessNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register as a Business'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registering as a business allows you to enjoy no collection fee but with a minimum booking limit of ₱500 instead of ₱200.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text('Contact Person:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Business/Organization Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final businessName = businessNameController.text.trim();

                if (firstName.isNotEmpty &&
                    lastName.isNotEmpty &&
                    businessName.isNotEmpty) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                        'firstName': firstName,
                        'lastName': lastName,
                        'businessName': businessName,
                        'category': 'business', // Classify the user as a business
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Business registration successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      throw Exception('User not logged in.');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterColumn(
                      'Our Scope',
                      [
                        'District 1, Davao City, Philippines',
                        'District 2, Davao City, Philippines',
                        'District 3, Davao City, Philippines'
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFooterColumn(
                      'About Us',
                      ['Our Story', 'Are You A Business?'],
                      actions: [
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsScreen(),
                              ),
                            ),
                        () => _showBusinessRegistrationModal(context),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFooterColumn('Contact Us', [
                      'kaagallawan@addu.edu.ph',
                      'anmlim@addu.edu.ph',
                      '09076211492'
                    ]),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterColumn(
                      'Our Scope',
                      [
                        'District 1, Davao City, Philippines',
                        'District 2, Davao City, Philippines',
                        'District 3, Davao City, Philippines'
                      ],
                    ),
                    _buildFooterColumn(
                      'About Us',
                      ['Our Story', 'Are You A Business?'],
                      actions: [
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsScreen(),
                              ),
                            ),
                        () => _showBusinessRegistrationModal(context),
                      ],
                    ),
                    _buildFooterColumn('Contact Us', [
                      'kaagallawan@addu.edu.ph',
                      'anmlim@addu.edu.ph',
                      '09076211492'
                    ]),
                  ],
                ),
        );
      },
    );
  }
}
