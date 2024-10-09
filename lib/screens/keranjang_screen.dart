import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'paymentScreen.dart';

class KeranjangScreen extends StatefulWidget {
  @override
  _KeranjangScreenState createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> _items = []; // Changed to _items
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isEditing = false;

  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _token = await _storage.read(key: 'token');
    String? userId = await _storage.read(key: 'userId');

    setState(() {
      _userId = int.tryParse(userId ?? '0');
    });

    print('User ID: $_userId');
    if (_userId != null) {
      _fetchCartItems();
    } else {
      setState(() {
        _errorMessage = 'User ID not found. Please log in again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url =
          Uri.parse('http://192.168.1.6:5000/api/keranjang?userId=$_userId');
      print('Fetching cart items from: $url');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched cart items: $data');
        setState(() {
          _items = data; // Changed to _items
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load cart items';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeCartItem(int id) async {
    try {
      final url = Uri.parse('http://192.168.1.6:5000/api/keranjang/$id');
      final response = await http.delete(url);

      if (response.statusCode == 204) {
        setState(() {
          _items.removeWhere((item) => item['id'] == id); // Changed to _items
        });
        _showSnackbar('Item removed from cart');
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackbar(errorData['error'] ?? 'Failed to remove item');
      }
    } catch (error) {
      _showSnackbar('An error occurred while removing item');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteSelectedItems() async {
    List<dynamic> itemsToDelete = _items
        .where((item) => item['isSelected'] == true)
        .toList(); // Changed to _items

    for (var item in itemsToDelete) {
      await _removeCartItem(item['id']);
    }

    setState(() {
      _items.removeWhere(
          (item) => item['isSelected'] == true); // Changed to _items
    });
  }

  String formatRupiah(int amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  Future<void> _updateCartItemQuantity(
      int cartId, int quantity, int userId, String ukuran) async {
    try {
      final url = Uri.parse('http://192.168.1.6:5000/api/keranjang/$cartId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
          'ukuran': ukuran, // Include ukuran in the request body
          'userId': userId, // Include userId in the request body
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar(
            'Cart item updated successfully'); // Show success snackbar
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackbar(errorData['error'] ?? 'Failed to update quantity');
      }
    } catch (error) {
      _showSnackbar('An error occurred while updating quantity');
    }
  }

  void _incrementQuantity(int index) {
    setState(() {
      _items[index]['quantity']++; // Changed to _items
    });

    int cartId = _items[index]['id']; // Get the cartId
    int userId = _items[index]['userId']; // Ensure userId is available
    String ukuran = _items[index]['ukuran']; // Get ukuran value from _items
    print('Cart ID (increment): $cartId'); // Print the cartId
    _updateCartItemQuantity(
        cartId, _items[index]['quantity'], userId, ukuran); // Pass ukuran
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_items[index]['quantity'] > 1) {
        _items[index]['quantity']--; // Changed to _items
        int cartId = _items[index]['id']; // Get the cartId
        int userId = _items[index]['userId']; // Ensure userId is available
        String ukuran = _items[index]['ukuran']; // Get ukuran value from _items
        print('Cart ID (decrement): $cartId'); // Print the cartId
        _updateCartItemQuantity(
            cartId, _items[index]['quantity'], userId, ukuran); // Pass ukuran
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _items.length, // Changed to _items
                          itemBuilder: (context, index) {
                            final item = _items[index]; // Changed to _items
                            final produkSepatu = item['produkSepatu'];
                            final harga = produkSepatu != null
                                ? produkSepatu['harga']
                                : 0;
                            final quantity = item['quantity'] ?? 0;
                            final totalPrice = harga * quantity;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item['isSelected'] ?? false,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          item['isSelected'] = value;
                                        });
                                      },
                                    ),
                                    produkSepatu != null &&
                                            produkSepatu['image'] != null
                                        ? Image.network(
                                            produkSepatu['image'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                          ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            produkSepatu != null
                                                ? produkSepatu['nama_sepatu']
                                                : 'Unknown Product',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove),
                                                onPressed: () =>
                                                    _decrementQuantity(index),
                                              ),
                                              Text('$quantity',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                              IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () =>
                                                    _incrementQuantity(index),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${formatRupiah(totalPrice)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _deleteSelectedItems,
              child: Icon(Icons.delete),
              backgroundColor: Colors.red,
            )
          : FloatingActionButton(
              onPressed: () {
                // Navigate directly to PaymentScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PaymentScreen(items: _items)), // Changed to _items
                );
              },
              child: Icon(Icons.payment),
            ),
    );
  }
}
