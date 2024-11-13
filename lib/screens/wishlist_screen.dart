import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;

import './product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> wishlistItems = [];
  bool isLoading = true;
  bool hasError = false;
  bool _isEditing = false; // Edit mode state
  final FlutterSecureStorage storage =
      FlutterSecureStorage(); // For retrieving userId
  String? userId; // Store userId here

  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
  }

  // Fetch wishlist items from API based on userId
// Fetch wishlist items from API based on userId
  Future<void> fetchWishlistItems() async {
    try {
      // Retrieve the userId from secure storage
      userId = await storage.read(key: 'userId');

      if (userId == null) {
        throw Exception(
            'User ID not found'); // Handle case if userId is not stored
      }

      // Make API request with userId
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/wishlist?userId=$userId'), // Adjust the URL with userId
      );

      if (response.statusCode == 200) {
        setState(() {
          wishlistItems = json.decode(response.body);

          // Initialize the 'isSelected' field to false for each item
          wishlistItems = wishlistItems.map((item) {
            item['isSelected'] =
                false; // Ensure 'isSelected' is always initialized
            return item;
          }).toList();

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

  // Delete selected wishlist items
  Future<void> deleteSelectedItems() async {
    List<dynamic> selectedItems =
        wishlistItems.where((item) => item['isSelected'] == true).toList();

    for (var item in selectedItems) {
      final id = item['id'].toString();

      // Print the type of id
      print('Type of id: ${id.runtimeType}');

      if (id != null) {
        final String idString = id.toString();
        try {
          final response = await http.delete(
            Uri.parse('http://10.0.2.2:5000/api/wishlist/$idString'),
          );

          if (response.statusCode == 200) {
            print('Wishlist item deleted: $idString');
          } else {
            print('Failed to delete item: $idString');
          }
        } catch (e) {
          print('Error deleting item: $e');
        }
      } else {
        print('No ID found for item: $item');
      }
    }

    // Fetch the updated wishlist after deletion
    fetchWishlistItems();
  }

  // Build the wishlist grid
  Widget _buildWishlistGrid(List<dynamic> wishlist) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int columns = (width / 200).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: (1 / 1.25),
          ),
          itemCount: wishlist.length,
          itemBuilder: (context, index) {
            final produk = wishlist[index];
            return _buildWishlistCard(produk);
          },
        );
      },
    );
  }

  Widget _buildWishlistCard(dynamic produk) {
    return GestureDetector(
      onTap: () {
        if (!_isEditing) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                id: produk['produkSepatu']['id'],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    children: [
                      Image.network(
                        produk['produkSepatu']['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 170,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      if (_isEditing)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Checkbox(
                            value: produk['isSelected'] ??
                                false, // Default to false if null
                            onChanged: (bool? value) {
                              setState(() {
                                produk['isSelected'] = value!;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                produk['produkSepatu']['nama_sepatu'] ?? 'Unknown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${produk['produkSepatu']['harga']}',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Wishlist',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Set the font weight to bold
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(child: Text('Error loading wishlist'))
                : wishlistItems.isEmpty
                    ? Center(child: Text('No items in wishlist'))
                    : _buildWishlistGrid(wishlistItems),
        // Bottom navigation bar for delete and checkout
        bottomNavigationBar: _isEditing
            ? BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Checkbox(
                        value: wishlistItems
                            .every((item) => item['isSelected'] == true),
                        onChanged: (bool? value) {
                          setState(() {
                            for (var item in wishlistItems) {
                              item['isSelected'] = value!;
                            }
                          });
                        },
                      ),
                      Text('Select All'),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: wishlistItems
                                  .any((item) => item['isSelected'] == true)
                              ? deleteSelectedItems
                              : null,
                          child: Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
