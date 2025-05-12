import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:localloop/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LocalLoopApp());
}

class LocalLoopApp extends StatelessWidget {
  const LocalLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalLoop',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const Scaffold(
        body: Center(child: Text('Welcome to LocalLoop')),
      ),
    );
  }
}
