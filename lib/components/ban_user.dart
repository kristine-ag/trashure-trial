import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BanUser extends StatefulWidget {
  const BanUser({Key? key}) : super(key: key);

  @override
  _BanUserState createState() => _BanUserState();
}

class _BanUserState extends State<BanUser> {
  bool _isBanned = false;
  List<Map<String, dynamic>> _reports = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkUserReports();
  }

  Future<void> _checkUserReports() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _userId = user.uid;

      // Fetch user's reports
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reports')
          .orderBy('datetimestamp', descending: true)
          .get();

      if (reportsSnapshot.docs.isEmpty) return;

      final reports = reportsSnapshot.docs.map((doc) {
        return {
          'datetimestamp': (doc['datetimestamp'] as Timestamp).toDate(),
          'reason': doc['reason'],
        };
      }).toList();

      setState(() {
        _reports = reports;
        _isBanned = reports.length >= 3;
      });

      if (reports.length >= 3) {
        _redirectToBanPage();
      } else if (reports.length == 1 || reports.length == 2) {
        _showWarning(reports.length);
      }
    } catch (e) {
      print('Error checking user reports: $e');
    }
  }

  void _redirectToBanPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BanPage(reports: _reports),
        ),
      );
    });
  }

  void _showWarning(int reportCount) {
    final warningMessage = reportCount == 1
        ? 'You have 1 report. Please be cautious as 3 reports will lead to a temporary ban.'
        : 'You have 2 reports. Another report will result in a temporary ban.';

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text(warningMessage),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Understood',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _isBanned
          ? const SizedBox.shrink() // Prevent access to other content if banned
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to the app!',
                    style: TextStyle(fontSize: 20),
                  ),
                  ElevatedButton(
                    onPressed: _checkUserReports, // Recheck reports if needed
                    child: const Text('Check Reports'),
                  ),
                ],
              ),
            ),
    );
  }
}

class BanPage extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const BanPage({Key? key, required this.reports}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Banned'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account has been temporarily banned due to 3 failed collections. Kindly contact the admin to resolve this problem',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send an email to anmlim@addu.edu.ph or call 09076211492',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Details of the reports:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.report, color: Colors.red),
                      title: Text('Reason: ${report['reason']}'),
                      subtitle: Text(
                        'Date: ${DateFormat('MM/dd/yyyy, hh:mm a').format(report['datetimestamp'])}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
