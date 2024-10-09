import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> wishlistItems = [];
  bool isLoading = true;
  bool hasError = false;
  final FlutterSecureStorage storage =
      FlutterSecureStorage(); // For retrieving userId
  String? userId; // Store userId here

  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
  }

// Fetch wishlist items from API based on userId
  Future<void> fetchWishlistItems() async {
    try {
      // Retrieve the userId from secure storage
      userId = await storage.read(key: 'userId');

      if (userId == null) {
        throw Exception(
            'User ID not found'); // Handle case if userId is not stored
      }

      // Print the userId to the console
      print('User ID: $userId');

      // Make API request with userId
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.6:5000/api/wishlist?userId=$userId'), // Adjust the URL with userId
      );

      if (response.statusCode == 200) {
        setState(() {
          wishlistItems = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load wishlist');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading state
          : hasError
              ? Center(child: Text('Error loading wishlist')) // Error state
              : wishlistItems.isEmpty
                  ? Center(child: Text('No items in wishlist')) // Empty state
                  : ListView.builder(
                      itemCount: wishlistItems.length,
                      itemBuilder: (context, index) {
                        final item = wishlistItems[index];
                        return ListTile(
                          title: Text(
                              item['produkSepatu']['nama_sepatu'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Harga: ${item['produkSepatu']['harga']}'),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
