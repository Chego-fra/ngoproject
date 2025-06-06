// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2mIDMD9kk7vGW-xdNHStHINSdfl-Iuww',
    appId: '1:931934896295:web:7f1e08aa9e047278165b82',
    messagingSenderId: '931934896295',
    projectId: 'ngoproject-2458e',
    authDomain: 'ngoproject-2458e.firebaseapp.com',
    storageBucket: 'ngoproject-2458e.firebasestorage.app',
    measurementId: 'G-S49D9RRDH7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJgptTmzRO0e8oaRG3Z1rlNo2CoXjF060',
    appId: '1:931934896295:android:7c7e36d31c33c369165b82',
    messagingSenderId: '931934896295',
    projectId: 'ngoproject-2458e',
    storageBucket: 'ngoproject-2458e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAr3vUZbdEJf_SP7e_erRbGIGYNtYBO46c',
    appId: '1:931934896295:ios:3f37478545265c39165b82',
    messagingSenderId: '931934896295',
    projectId: 'ngoproject-2458e',
    storageBucket: 'ngoproject-2458e.firebasestorage.app',
    iosBundleId: 'com.example.localloop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAr3vUZbdEJf_SP7e_erRbGIGYNtYBO46c',
    appId: '1:931934896295:ios:3f37478545265c39165b82',
    messagingSenderId: '931934896295',
    projectId: 'ngoproject-2458e',
    storageBucket: 'ngoproject-2458e.firebasestorage.app',
    iosBundleId: 'com.example.localloop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB2mIDMD9kk7vGW-xdNHStHINSdfl-Iuww',
    appId: '1:931934896295:web:95a8a334a3387c39165b82',
    messagingSenderId: '931934896295',
    projectId: 'ngoproject-2458e',
    authDomain: 'ngoproject-2458e.firebaseapp.com',
    storageBucket: 'ngoproject-2458e.firebasestorage.app',
    measurementId: 'G-FW24E7B1V0',
  );
}
