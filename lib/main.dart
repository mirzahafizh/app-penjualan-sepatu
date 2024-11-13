import 'package:flutter/material.dart';

import './screens/AccountSettingsScreen.dart';
import './screens/MyOrdersScreen.dart';
import './screens/home_screen.dart';
import './screens/keranjang_screen.dart';
import './screens/login_screen.dart';
import './screens/profile_screen.dart';
import './screens/wishlist_screen.dart';

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
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Courier', // Set the default font family for the app
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/accountSettings': (context) => AccountSettingsScreen(),
        '/cart': (context) => KeranjangScreen(),
        '/wishlist': (context) => WishlistScreen(),
        '/profile': (context) => ProfilScreen(),
        '/transactionHistory': (context) => MyOrdersScreen(),
      },
    );
  }
}
