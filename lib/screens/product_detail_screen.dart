import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import this package

class ProductDetailScreen extends StatefulWidget {
  final int id;

  ProductDetailScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  late int userId;
  String token = '';
  List<dynamic> comments = [];
  int commentsLimit = 3;
  Map<String, dynamic> product = {};
  bool isLoading = true;
  String selectedSize = '';
  List<String> sizes = []; // List to store available sizes from product

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchProduct();
    _fetchComments();
  }

  Future<void> _loadUserData() async {
    String? userIdString = await _storage.read(key: 'userId');
    String? tokenString = await _storage.read(key: 'token');

    if (userIdString != null) {
      userId = int.parse(userIdString);
    } else {
      userId = 0;
    }
    token = tokenString ?? '';

    setState(() {});
  }

  Future<void> _fetchProduct() async {
    final url = 'http://192.168.1.6:5000/api/produk-sepatu/${widget.id}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('$data');
        setState(() {
          product = data;
          sizes = List<String>.from(
              json.decode(product['ukuran'])); // Update available sizes
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching product: $error');
    }
  }

  Future<void> _fetchComments() async {
    final url =
        'http://192.168.1.6:5000/api/comments/product/${widget.id}'; // Adjust endpoint as necessary

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include the token in the headers
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(response.body); // Decode as a list

        // Check if the data is a list and handle accordingly
        if (data is List) {
          setState(() {
            comments = data; // Set comments to the response list
          });
        } else {
          print('Unexpected response format, expected a list.');
        }
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching comments: $error');
    }
  }

  Future<void> addToCart(BuildContext context) async {
    final url =
        'http://192.168.1.6:5000/api/keranjang'; // Endpoint to add to cart
    final body = json.encode({
      'userId': userId,
      'produkSepatuId': widget.id,
      'quantity': 1, // Set quantity as needed
      'ukuran': selectedSize
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Produk berhasil ditambahkan ke keranjang'),
        ));
      } else {
        throw Exception('Failed to add to cart');
      }
    } catch (error) {
      print('Error adding to cart: $error');
    }
  }

  Future<void> addToWishlist(BuildContext context) async {
    final url =
        'http://192.168.1.6:5000/api/wishlist'; // Endpoint to add to wishlist

    final body = json.encode({
      'userId': userId,
      'produkSepatuId': widget.id,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include the token in the headers
        },
        body: body,
      );

      if (response.statusCode == 201) {
        // Jika berhasil ditambahkan ke wishlist
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Produk berhasil ditambahkan ke wishlist'),
        ));
      } else if (response.statusCode == 400) {
        // Jika item sudah ada di wishlist
        final responseBody = json.decode(response.body);
        if (responseBody['error'] == 'Item already exists in wishlist') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Produk sudah ada di wishlist'),
          ));
        } else {
          throw Exception('Failed to add to wishlist');
        }
      } else {
        throw Exception('Failed to add to wishlist');
      }
    } catch (error) {
      print('Error adding to wishlist: $error');
    }
  }

  void _loadMoreComments() {
    setState(() {
      commentsLimit += 3; // Increase the limit for loading more comments
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['nama_sepatu'] ?? 'Loading...'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      product['image'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    product['nama_sepatu'] ?? 'Loading...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      if (index < (product['rating']?.floor() ?? 0)) {
                        return Icon(Icons.star, color: Colors.yellow);
                      } else if (index < (product['rating'] ?? 0) &&
                          (product['rating'] - index >= 0.5)) {
                        return Icon(Icons.star_half, color: Colors.yellow);
                      } else {
                        return Icon(Icons.star_border, color: Colors.yellow);
                      }
                    }),
                  ),
                  Text(
                    'Harga: Rp ${NumberFormat('#,##0').format(product['harga'] ?? 0)}', // Format the price
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),

                  // Size Selection using Horizontal Boxes
                  Text(
                    'Pilih Ukuran:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: sizes.map((String size) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSize = size; // Update selected size on tap
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          margin: EdgeInsets.symmetric(
                              horizontal: 4), // Margin for tight packing
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedSize == size
                                  ? Colors.blue
                                  : Colors
                                      .grey, // Change border color if selected
                            ),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16), // Add some space after size selection
                  Text(
                    product['deskripsi'] ?? 'No description available',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Komentar:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: commentsLimit > comments.length
                        ? comments.length
                        : commentsLimit,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        title: Text(comment['User']['fullName'] ?? 'Anonymous'),
                        subtitle: Text(comment['comment_text'] ?? 'No content'),
                      );
                    },
                  ),
                  if (comments.length > commentsLimit)
                    TextButton(
                      onPressed: _loadMoreComments,
                      child: Text('Lebih Banyak'),
                    ),
                  SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.black),
              onPressed: () => addToCart(context),
              tooltip: 'Keranjang',
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.black),
              onPressed: () => addToWishlist(context),
              tooltip: 'Wishlist',
            ),
          ],
        ),
      ),
    );
  }
}
