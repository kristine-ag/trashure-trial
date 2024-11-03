import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashure/components/address.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage; // Add a variable to store error messages

  Future<void> _login() async {
    setState(() {
      _errorMessage = null; // Clear previous error messages
    });

    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage = 'Please verify your email before logging in.';
          });
        } else if (user != null) {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (docSnapshot.exists && docSnapshot.get('contact') == '') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ContactSetupScreen(userId: user.uid),
              ),
            );
          } else {
            _redirectToLastRoute();
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'No user found with this email.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Incorrect password. Please try again.';
          } else {
            _errorMessage = 'Incorrect Email or Password. Try signing up.';
          }
        });
      } catch (e) {
        // Handle any other errors
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  Future<void> _redirectToLastRoute() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastRoute = prefs.getString('lastRoute');

    if (lastRoute != null && lastRoute.isNotEmpty) {
      Navigator.pushReplacementNamed(context, lastRoute);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Side - Form Section
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Animated Welcome Text
                    Center(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 24.0,
                          color: Colors.black,
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText('Login to Trashure'),
                          ],
                          repeatForever: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Display error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text(
                              "I don't have an account",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right Side - Image Section
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
