import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trashure/main.dart';

// Kristine Firebase
// const firebaseConfig = FirebaseOptions(
//   apiKey: "AIzaSyAjQu-KmwK5-zyrw3TszSurCuts-ylLHrY",
//   authDomain: "trashure-d95da.firebaseapp.com",
//   projectId: "trashure-d95da",
//   storageBucket: "trashure-d95da.appspot.com",
//   messagingSenderId: "621032929808",
//   appId: "1:621032929808:web:6c35f5f1d6b69c6f16a895",
//   measurementId: "G-HSHYRVRFGH"
// );

// Ashley Firebase
const firebaseConfig = FirebaseOptions (
  apiKey: "AIzaSyCEyCfsNSldvuqYszhxIGsVqJvqLfdHD0Y",
  authDomain: "thesis-5212b.firebaseapp.com",
  projectId: "thesis-5212b",
  storageBucket: "thesis-5212b.appspot.com",
  messagingSenderId: "75792807749",
  appId: "1:75792807749:web:6d301a27869d6cdd07f02c",
  measurementId: "G-1F6X7DDHTN"
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? firebaseConfig : null,
  );
  runApp(MyApp());
}
