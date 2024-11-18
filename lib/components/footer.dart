import 'package:flutter/material.dart';
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
                      ['Our Story', 'Work with us'],
                      actions: [
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsScreen(),
                              ),
                            ),
                        null, // No action for 'Work with us'
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
                      ['Our Story', 'Work with us'],
                      actions: [
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsScreen(),
                              ),
                            ),
                        null, // No action for 'Work with us'
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
