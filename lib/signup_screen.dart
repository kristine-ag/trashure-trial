// ignore_for_file: prefer_const_constructors

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name': _nameController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup Successful!')),
          );

          print('User added to Firestore with UID: ${user.uid}');

          Navigator.pushReplacementNamed(context, '/');
        } else {
          print('User is null');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User is already registered. Log in to continue.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup Failed: $e')),
          );
        }
        print('Signup Failed: $e');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        User? user = userCredential.user;

        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'name': googleUser.displayName,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Sign-In Successful!')),
          );

          Navigator.pushReplacementNamed(context, '/');
        } else {
          print('User is null');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Failed: $e')),
      );
      print('Google Sign-In Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 4.0,
              shadowColor: Color.fromRGBO(26, 33, 52, 0.11),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 460.0,
                    minWidth: 320.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: SizedBox(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 30.0,
                              color: Colors.teal[400],
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText('Welcome to Trashure'),
                                TypewriterAnimatedText('Create Your Account'),
                              ],
                              repeatForever: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
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
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Divider(),
                            SizedBox(height: 16.0),
                            _buildSocialLoginButton(
                              'Sign up with Google',
                              FontAwesomeIcons.google,
                              _signInWithGoogle,
                            ),
                            SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Text(
                                'Already have an account? Log In',
                                style: TextStyle(color: Colors.teal[800]),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Terms and Conditions · Privacy Policy · CA Privacy Notice',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 24.0),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
