import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trashure/main.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAjQu-KmwK5-zyrw3TszSurCuts-ylLHrY",
  authDomain: "trashure-d95da.firebaseapp.com",
  projectId: "trashure-d95da",
  storageBucket: "trashure-d95da.appspot.com",
  messagingSenderId: "621032929808",
  appId: "1:621032929808:web:6c35f5f1d6b69c6f16a895",
  measurementId: "G-HSHYRVRFGH"
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? firebaseConfig : null,
  );
  runApp(MyApp());
}
