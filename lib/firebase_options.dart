import 'package:firebase_core/firebase_core.dart';

/// Client-side Firebase config for the web build (no secrets). Android reads
/// `android/app/google-services.json` instead.
const webFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBNz50KHBAqHkcxg1BxpNQ3tBjosRkIdH8',
  appId: '1:187400736265:web:0d60917a08c557ef0b72d8',
  messagingSenderId: '187400736265',
  projectId: 'bookshelf-prm393-2610',
  authDomain: 'bookshelf-prm393-2610.firebaseapp.com',
  storageBucket: 'bookshelf-prm393-2610.firebasestorage.app',
);
