import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/components/branches.dart';
import 'package:trashure/screens/booking_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required Widget screen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton(
        onPressed: () => _navigateToScreen(context, screen),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          side: const BorderSide(color: Colors.green, width: 2), // Green border color
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.green, // Text color matches the border
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                context: context,
                text: 'Deliver your recyclable trash to trashure!',
                screen: const OnSiteScreen(),
              ),
              _buildButton(
                context: context,
                text: 'Book a recyclable trash collection date with trashure!',
                screen: const BookingScreen(mode: 'booking'),
              ),
              _buildButton(
                context: context,
                text: 'Donate your recyclable trash to trashure!',
                screen: const BookingScreen(mode: 'donate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
