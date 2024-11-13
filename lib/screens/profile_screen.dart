import 'dart:convert'; // Import for JSON encoding/decoding

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfilScreen extends StatefulWidget {
  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FlutterSecureStorage storage =
      FlutterSecureStorage(); // Initialize secure storage
  String? fullName; // Variable to hold the user's full name
  String? imageUrl; // Variable to hold the user's image URL
  String? userId; // Variable to hold the user's ID

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the screen initializes
  }

  Future<void> _loadUserData() async {
    // Load user ID from secure storage
    userId = await storage.read(key: 'userId');
    // Load user data from the API
    if (userId != null) {
      await _fetchUserData(userId!);
    }
  }

  Future<void> _fetchUserData(String id) async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/users/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fullName =
              data['fullName']; // Assuming the API returns a 'fullName' field
          imageUrl =
              data['image']; // Fetch the user's image from the 'image' field
        });
      } else {
        // Handle error, e.g., show a message
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, navigate to the home screen
        Navigator.pushReplacementNamed(context, '/home');
        return false; // Prevent the default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              Colors.white, // Ubah color.white menjadi Colors.white
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Set the font weight to bold
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back), // Back button icon
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ),
        backgroundColor: Colors.white, // Set the background color here
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // User Profile Section
              if (imageUrl != null) // Check if imageUrl is not null
                CircleAvatar(
                  radius: 50, // Radius of the circular image
                  backgroundImage: NetworkImage(imageUrl!), // Fetched image URL
                )
              else
                SizedBox(
                  width: 50, // Size of the placeholder
                  height: 50,
                ),
              SizedBox(height: 10),
              Text(
                fullName ??
                    'Nama Pengguna', // Display user's name or placeholder
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Settings Menu
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          'Pengaturan Akun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          // Navigate to account settings page
                          Navigator.pushNamed(context, '/accountSettings');
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                          thickness: 1), // Divider after Pengaturan Akun
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          'History Transaksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          // Navigate to transaction history page
                          Navigator.pushNamed(context, '/transactionHistory');
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                          thickness: 1), // Divider after History Transaksi
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          // Clear all secure storage
                          await storage.deleteAll();
                          // Navigate back to the login screen
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
