import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MyOrdersScreen extends StatefulWidget {
  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> inProcessOrders = [];
  List<dynamic> shippedOrders = [];
  List<dynamic> receivedOrders = [];
  final FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      String? userId = await storage.read(key: 'userId');
      final String url = 'http://192.168.1.6:5000/api/transaksi/user/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> allOrders = jsonDecode(response.body);

        setState(() {
          inProcessOrders = allOrders
              .where((order) => order['status_pengiriman'] == 'di proses')
              .toList();
          shippedOrders = allOrders
              .where((order) => order['status_pengiriman'] == 'dikirim')
              .toList();
          receivedOrders = allOrders
              .where((order) => order['status_pengiriman'] == 'diterima')
              .toList();
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print('Error fetching orders: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Di Proses'),
            Tab(text: 'Dikirim'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(inProcessOrders),
          _buildOrderList(shippedOrders),
          _buildOrderList(receivedOrders),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(child: Text('No orders available.'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final produkSepatu = order['produkSepatu'];

        return ListTile(
          title: Text(produkSepatu != null
              ? produkSepatu['nama_sepatu'] ?? 'Unknown Shoe'
              : 'Unknown Shoe'),
          subtitle: Text(
            'Total: ${order['totalAmount']} \n'
            'Status: ${order['paymentStatus']} \n'
            'Size: ${order?['ukuran']}\n'
            'Price: ${produkSepatu?['harga']}',
            style: TextStyle(fontSize: 14),
          ),
          leading: produkSepatu?['image'] != null
              ? Image.network(produkSepatu['image'], width: 50, height: 50)
              : null,
          isThreeLine: true,
          trailing: order['status_pengiriman'] == 'diterima'
              ? TextButton(
                  onPressed: () {
                    print(
                        'Rate button pressed for produkSepatuId: ${produkSepatu['id']}'); // Debug print
                    _showRatingDialog(produkSepatu['id']);
                  },
                  child: Text('Rate'),
                )
              : null,
        );
      },
    );
  }

  void _showRatingDialog(int produkSepatuId) {
    double rating = 0; // Initialize rating to 0

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Please rate your product:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating ? Colors.yellow : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index +
                                1.0; // Update rating based on star index
                          });
                          print(
                              'Selected Rating: $rating'); // Print the selected rating
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (rating > 0) {
                      // Call your API to submit the rating here
                      _submitRating(produkSepatuId.toString(), rating.round());
                      Navigator.of(context).pop(); // Close the dialog
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a rating')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitRating(String produkSepatuId, int rating) async {
    // Construct the URL
    final url =
        'http://192.168.1.6:5000/api/produk-sepatu/$produkSepatuId/rating';

    // Construct the body
    final body = jsonEncode({"rating": rating});

    // Print the URL and body for debugging
    print('Submitting rating to URL: $url');
    print('Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Handle successful rating submission
        print('Rating submitted successfully');
      } else {
        // Handle error
        print('Failed to submit rating: ${response.body}');
      }
    } catch (error) {
      print('Error submitting rating: $error');
    }
  }
}
