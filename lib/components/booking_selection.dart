import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';
import 'package:trashure/screens/booking_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildSquareButton({
    required BuildContext context,
    required String text,
    required Widget screen,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _navigateToScreen(context, screen),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 50), // Square shape
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
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
              const Text(
                "How would you like to save our planet?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildSquareButton(
                    context: context,
                    text: 'Sell your segregated recyclable trash to trashure',
                    screen: const BookingScreen(mode: 'booking'),
                  ),
                  _buildSquareButton(
                    context: context,
                    text: 'Donate your segregated recyclable trash to trashure',
                    screen: const BookingScreen(mode: 'donate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
