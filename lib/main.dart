import 'package:flutter/material.dart';
import 'package:realestate/Screens/login.dart';

// Define color constants here directly
const kPrimaryColor = Color.fromARGB(255, 11, 97, 236);
const kSecondaryColor = Color(0xFF004D40);
const kTextColor = Color(0xFF212121);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REAL ESTATE',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage(),
    );
  }
}
