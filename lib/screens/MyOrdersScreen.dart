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
  // To track ratings for each product
  Map<int, double> productRatings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      String? userId = await storage.read(key: 'userId');
      final String url = 'http://10.0.2.2:5000/api/transaksi/user/$userId';
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

  void _updateOrderStatus(int orderId, String newStatus) async {
    final url = 'http://10.0.2.2:5000/api/transaksi/$orderId';
    final body = jsonEncode({"status_pengiriman": newStatus});

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Order status updated successfully');
        fetchOrders();
      } else {
        print('Failed to update order status: ${response.body}');
      }
    } catch (error) {
      print('Error updating order status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                child: Text('Di Proses',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Tab(
                child: Text('Dikirim',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Tab(
                child: Text('Selesai',
                    style: TextStyle(fontWeight: FontWeight.bold))),
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
          contentPadding: EdgeInsets.all(8.0),
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              produkSepatu?['image'] != null
                  ? Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      child: Image.network(
                        produkSepatu['image'],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                  : SizedBox(width: 70),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produkSepatu != null
                          ? produkSepatu['nama_sepatu'] ?? 'Unknown Shoe'
                          : 'Unknown Shoe',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: ${order['totalAmount']}',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Size: ${order?['ukuran']}',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Price: ${produkSepatu?['harga']}',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: _buildTrailingButton(order, produkSepatu),
        );
      },
    );
  }

  Widget _buildTrailingButton(dynamic order, dynamic produkSepatu) {
    // Check if the product has already been rated
    if (productRatings.containsKey(produkSepatu['id'])) {
      return Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: TextButton(
          onPressed: () {
            // Optional: Show message that the user has already rated
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You have already rated this product.')),
            );
          },
          child: Text('Rated: ${productRatings[produkSepatu['id']]!} stars'),
        ),
      );
    }

    // Display the rating button only if the order is 'diterima'
    if (order['status_pengiriman'] == 'diterima') {
      return Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: TextButton(
          onPressed: () {
            print(
                'Rate button pressed for produkSepatuId: ${produkSepatu['id']}');
            _showRatingDialog(produkSepatu['id']);
          },
          child: Text('Rate'),
        ),
      );
    } else if (order['status_pengiriman'] == 'dikirim') {
      return Container(
        margin: const EdgeInsets.only(top: 25.0),
        child: TextButton(
          onPressed: () {
            _updateOrderStatus(order['id'], 'diterima');
          },
          child: Text('Diterima',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return SizedBox(); // Return an empty widget if no actions are needed
  }

  void _showRatingDialog(int produkSepatuId) {
    double rating = 0;
    TextEditingController _commentController =
        TextEditingController(); // Controller untuk komentar

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
                  Text('Please rate this product:'),
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
                                1.0; // Update rating berdasarkan jumlah bintang
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),

                  // Tambahan kolom komentar
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText:
                          'Write your comment', // Label untuk kolom komentar
                      border:
                          OutlineInputBorder(), // Membuat border pada kolom komentar
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (rating > 0 && _commentController.text.isNotEmpty) {
                      _submitRating(produkSepatuId.toString(), rating.round(),
                          _commentController.text);
                      Navigator.of(context).pop(); // Tutup dialog
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Please select a rating and write a comment')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
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

  void _submitRating(String produkSepatuId, int rating, String comment) async {
    final url = 'http://10.0.2.2:5000/api/produk-sepatu/$produkSepatuId/rating';
    final body = jsonEncode({"rating": rating});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Save the rating for the product
        setState(() {
          productRatings[int.parse(produkSepatuId)] = rating.toDouble();
        });
        print('Rating submitted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted: $rating stars')),
        );
      } else {
        print('Failed to submit rating: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } catch (error) {
      print('Error submitting rating: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating')),
      );
    }
  }
}
