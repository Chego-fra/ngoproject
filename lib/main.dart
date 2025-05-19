import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:localloop/firebase_options.dart';
import 'package:localloop/screens/admin/admin_dashboard.dart';
import 'package:localloop/screens/auth/login_screen.dart';
import 'package:localloop/screens/ngo/ngo_dashboard.dart';
import 'package:localloop/screens/volunteer/voluteer_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LocalLoopApp());
}

class LocalLoopApp extends StatelessWidget {
  const LocalLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication',
      theme:  ThemeData(useMaterial3: true),
    initialRoute: FirebaseAuth.instance.currentUser  == null ? 'login' : 'home',
    routes: {
      '/login':(context) =>  LoginScreen(),
      '/admin':(context) => const  AdminHome(),
      '/ngo':(context) => const NgoHome(),
      '/voluteer':(context) => const VolunteerHome(),
    },
    home:  LoginScreen(),
    );
  }
}
