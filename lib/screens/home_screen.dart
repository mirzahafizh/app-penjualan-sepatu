import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'beranda_screen.dart';
import 'keranjang_screen.dart';
import 'profile_screen.dart';
import 'search_result_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  int _currentIndex = 0;
  String? token;
  int? userId;
  String? fullName;
  String? email;
  String? role;
  String _searchQuery = ''; // For storing the search query

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    token = await storage.read(key: 'token');
    userId = int.tryParse(await storage.read(key: 'id') ?? '0');
    fullName = await storage.read(key: 'fullName');
    email = await storage.read(key: 'email');
    role = await storage.read(key: 'role');

    setState(() {}); // Rebuild UI after loading data
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = fullName == null
        ? Center(child: CircularProgressIndicator())
        : _getCurrentScreen();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF001F3F), // Dark blue color
        automaticallyImplyLeading: false, // Remove back button

        title: Row(
          children: [
            SizedBox(width: 0), // Space before the search bar
            Expanded(
              child: Container(
                height: 40, // Set the height for the search bar
                decoration: BoxDecoration(
                  color: Colors.white, // Background color for search bar
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  textAlign:
                      TextAlign.start, // Align text to the left horizontally
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey), // Search icon
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ), // Adjust vertical and horizontal padding
                  ),
                  style: TextStyle(color: Colors.black), // Text color
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query; // Update search query
                    });
                  },
                  onSubmitted: (query) {
                    // Navigate to the search results page when the user submits the query
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchResultsScreen(searchQuery: query),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(0xFF001F3F), // Dark blue background
        child: bodyContent,
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return BerandaScreen(); // Pass the search query to BerandaScreen
      case 1:
        return KeranjangScreen();
      case 2:
        return WishlistScreen();
      case 3:
        return ProfilScreen();
      default:
        return BerandaScreen(); // Default to BerandaScreen
    }
  }

  Widget _buildCustomBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.white, // Background color for BottomAppBar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Beranda', 0),
          _buildNavItem(Icons.shopping_cart, 'Keranjang', 1),
          _buildNavItem(Icons.favorite, 'Wishlist', 2),
          _buildNavItem(Icons.person, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        // Add your navigation logic here
        switch (index) {
          case 0:
            // Tetap di HomeScreen
            break;
          case 1:
            Navigator.pushNamed(context, '/cart');
            break;
          case 2:
            Navigator.pushNamed(context, '/wishlist');
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: _currentIndex == index ? Colors.black : Colors.black),
          Text(
            label,
            style: TextStyle(
              color: _currentIndex == index ? Colors.black : Colors.black,
              fontWeight: FontWeight.bold, // Make the text bold
            ),
          ),
        ],
      ),
    );
  }
}
