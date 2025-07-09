import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realestate/Screens/login.dart';
import 'package:device_preview/device_preview.dart';

// Define color constants
const kPrimaryColor = Color.fromARGB(255, 11, 97, 236);
const kSecondaryColor = Color(0xFF004D40);
const kTextColor = Color(0xFF212121);

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Automatically disables in release mode
      builder: (context) => const MyApp(), // Wrap your app
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REAL ESTATE',
      useInheritedMediaQuery:
          true, // Required for device_preview to work correctly
      locale: DevicePreview.locale(context), // Pass the simulated locale
      builder: DevicePreview.appBuilder, // Apply the preview builder
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
    );
  }
}
