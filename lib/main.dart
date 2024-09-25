// ignore_for_file: prefer_const_constructors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trashure/maptrial.dart';
import 'package:trashure/screens/address_screen.dart';
import 'package:trashure/screens/booking_screen.dart';
import 'package:trashure/screens/booksched_screen.dart';
import 'package:trashure/screens/pricing_screen.dart';
import 'package:trashure/screens/profile_screen.dart';
import 'components/firebase_options.dart';
import 'registration/signup_screen.dart';
import 'registration/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? firebaseConfig : null,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRASHURE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => HomeScreen(),
        '/Home': (context) => HomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/Book': (context) => BookingScreen(),
        '/Address': (context) => AddressScreen(),
        '/Pricing': (context) => PricingScreen(),
        '/Schedule': (context) => BookSchedScreen(),
        '/Profile': (context) => ProfileScreen(),
        '/map': (context) => GoogleMapPage(),


      },
    );
  }
}
