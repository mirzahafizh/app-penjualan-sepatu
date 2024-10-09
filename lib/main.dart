import 'package:flutter/material.dart';

import './screens/AccountSettingsScreen.dart'; // Import the AccountSettingsScreen
import './screens/home_screen.dart'; // Import the HomeScreen
import './screens/keranjang_screen.dart';
import './screens/login_screen.dart'; // Import the LoginScreen
import 'screens/MyOrdersScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login & Register',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity:
            VisualDensity.adaptivePlatformDensity, // Adjust visual density
      ),
      home: LoginScreen(), // Start with the LoginScreen
      debugShowCheckedModeBanner: false, // Disable the debug banner
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(), // No arguments passed here
        '/accountSettings': (context) =>
            AccountSettingsScreen(), // No arguments passed here
        '/cart': (context) => KeranjangScreen(), // No arguments passed here
        '/transactionHistory': (context) => MyOrdersScreen(),
      },
    );
  }
}
