// ignore_for_file: prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Sign in the user
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          // Email not verified, show a modal and allow to resend verification email
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Email Not Verified'),
              content: Text(
                  'Please verify your email. Check your inbox or tap Resend to receive a new verification email.'),
              actions: [
                TextButton(
                  child: Text('Resend'),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    await user.sendEmailVerification();
                    // Show another dialog confirming that email was sent
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Verification Email Sent'),
                        content:
                            Text('Verification email sent! Please check your inbox.'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
          await FirebaseAuth.instance.signOut(); // Sign out the user
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'invalid-email':
            message = 'The email address is not valid.';
            break;
          case 'user-disabled':
            message =
                'The user corresponding to the given email has been disabled.';
            break;
          case 'user-not-found':
            message = 'No user found for the given email.';
            break;
          case 'wrong-password':
            message = 'The password is invalid for the given email.';
            break;
          default:
            message = 'Invalid Email or Password. Try Signing Up!';
        }
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text(message),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } catch (e) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text('Login Failed: ${e.toString()}'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        User? user = userCredential.user;

        if (user != null) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Google Sign-In Successful'),
              content: Text('You have successfully signed in with Google.'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _redirectToLastRoute();
                  },
                ),
              ],
            ),
          );
        } else {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Google Sign-In Failed'),
              content: Text('Google Sign-In Failed: User is null'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Google Sign-In Failed'),
          content: Text('Google Sign-In Failed'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
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
              shadowColor: const Color.fromRGBO(26, 33, 52, 0.11),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  constraints: const BoxConstraints(
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
                                TypewriterAnimatedText(
                                    'Log In to Your Account'),
                              ],
                              repeatForever: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
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
                                backgroundColor: Colors.teal[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () async {
                                TextEditingController emailController =
                                    TextEditingController(
                                        text: _emailController.text);

                                bool? shouldReset = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Reset Password'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                              'Please enter your email to receive a password reset link.'),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: emailController,
                                            decoration: const InputDecoration(
                                              labelText: 'Email',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                        ),
                                        TextButton(
                                          child: const Text('Send'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldReset == true) {
                                  String email = emailController.text.trim();
                                  // Validate the email
                                  if (email.isEmpty) {
                                    // Show error dialog
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Invalid Email'),
                                        content:
                                            const Text('Please enter your email'),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(email)) {
                                    // Show error dialog
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Invalid Email'),
                                        content: const Text(
                                            'Please enter a valid email address'),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);
                                    // Show success dialog
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Email Sent'),
                                        content: Text(
                                            'Password reset email sent to $email'),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    // Handle Firebase specific errors
                                    String message;
                                    switch (e.code) {
                                      case 'invalid-email':
                                        message =
                                            'The email address is not valid.';
                                        break;
                                      case 'user-not-found':
                                        message =
                                            'No user found for the given email.';
                                        break;
                                      default:
                                        message =
                                            'Error sending password reset email: ${e.message}';
                                    }
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Error'),
                                        content: Text(message),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    // General error
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Error'),
                                        content: Text(
                                            'Error sending password reset email: ${e.toString()}'),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text("Forgot your Password?"),
                            ),
                            const Divider(),
                            // const SizedBox(height: 16.0),
                            // _buildSocialLoginButton(
                            //   'Log in with Google',
                            //   FontAwesomeIcons.google,
                            //   _signInWithGoogle,
                            // ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Text(
                                "I don't have an account",
                                style: TextStyle(color: Colors.teal[800]),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            const Divider(),
                            const Text(
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

  Widget _buildSocialLoginButton(
      String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 24.0),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
