// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:localloop/firebase_options.dart';
import 'package:localloop/screens/admin/admin_dashboard.dart';
import 'package:localloop/screens/auth/login_screen.dart';
import 'package:localloop/screens/ngo/ngo_dashboard.dart';
import 'package:localloop/screens/volunteer/voluteer_dashboard.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: \${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initializeLocalNotifications();
  runApp(const LocalLoopApp());
}

/// Initialize local notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      print('Notification clicked. Payload: \$payload');
      // Optional: Add logic to navigate based on payload
    },
  );
}

class LocalLoopApp extends StatefulWidget {
  const LocalLoopApp({super.key});

  @override
  State<LocalLoopApp> createState() => _LocalLoopAppState();
}

class _LocalLoopAppState extends State<LocalLoopApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  /// Setup Firebase Messaging and foreground notification handling
  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission();
    print('User granted permission: \${settings.authorizationStatus}');

    // Get FCM token
    String? token = await messaging.getToken();
    print("FCM Token: \$token");

    // Save token to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }

    // Foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Notifications',
              channelDescription: 'Used for important notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // When app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('User tapped on notification: \${message.data}');
      // You can handle navigation logic based on message.data here
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLoop',
      theme: ThemeData(useMaterial3: true),
      initialRoute: user == null
          ? '/login'
          : user.metadata.creationTime == user.metadata.lastSignInTime
              ? '/login'
              : '/role', // Temporary route to decide by Firestore role
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin': (context) => const AdminHome(),
        '/ngo': (context) => const NgoHome(),
        '/voluteer': (context) => const VolunteerHome(),
      },
      home: user == null
          ? LoginScreen()
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const LoginScreen();
                }

                final role = snapshot.data!.get('role');
                if (role == 'admin') return const AdminHome();
                if (role == 'ngo') return const NgoHome();
                return const VolunteerHome();
              },
            ),
    );
  }
}
