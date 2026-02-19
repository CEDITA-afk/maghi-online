import 'package:flutter/material.dart';
import 'ui/screens/setup/setup_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INSERISCI QUI I TUOI DATI COPIATI DALLA CONSOLE FIREBASE
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyChO4jkGg7bYQvY5-jB2JPY-s6SlzqbS48",
      authDomain: "bg-app-558f4.firebaseapp.com",
      projectId: "bg-app-558f4",
      storageBucket: "bg-app-558f4.firebasestorage.app",
      messagingSenderId: "795638347546",
      appId: "1:795638347546:web:2913ffbe96d5ffdeef9ea3",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maghi Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const SetupPage(),
    );
  }
}