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
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isEditing = false;
  String? _address;
  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Ensure this is called
  }

  Future<void> _loadUserData() async {
    // Read the token and user ID from storage
    _token = await _storage.read(key: 'token');
    String? userId = await _storage.read(key: 'userId');

    setState(() {
      _userId = int.tryParse(userId ?? '0');
      _isLoading = true; // Set loading to true while fetching data
    });

    print('User ID: $_userId');

    if (_userId != null) {
      // Fetch user address after successfully loading the user ID
      await _fetchUserAddress(_userId!);
      // Optionally fetch cart items if needed
      await _fetchCartItems();
    } else {
      setState(() {
        _errorMessage = 'User ID not found. Please log in again.';
        _isLoading = false; // Set loading to false on error
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
          Uri.parse('http://10.0.2.2:5000/api/keranjang?userId=$_userId');
      print('Fetching cart items from: $url');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched cart items: $data');
        setState(() {
          _items = data;
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

  Future<void> _fetchUserAddress(int userId) async {
    try {
      final url = Uri.parse('http://10.0.2.2:5000/api/users/$userId');
      print('Fetching address from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _address = data['address']; // Assuming the address is in the response
        });

        // Print the fetched address
        print('Fetched address: $_address');
      } else {
        setState(() {
          _errorMessage = 'Failed to load user address';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
    }
  }

  Future<void> _removeCartItem(int id) async {
    try {
      final url = Uri.parse('http://10.0.2.2:5000/api/keranjang/$id');
      final response = await http.delete(url);

      if (response.statusCode == 204) {
        setState(() {
          _items.removeWhere((item) => item['id'] == id);
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
    List<dynamic> itemsToDelete =
        _items.where((item) => item['isSelected'] == true).toList();

    for (var item in itemsToDelete) {
      await _removeCartItem(item['id']);
    }

    setState(() {
      _items.removeWhere((item) => item['isSelected'] == true);
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
      final url = Uri.parse('http://10.0.2.2:5000/api/keranjang/$cartId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
          'ukuran': ukuran,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Cart item updated successfully');
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
      _items[index]['quantity']++;
    });

    int cartId = _items[index]['id'];
    int userId = _items[index]['userId'];
    String ukuran = _items[index]['ukuran'];
    print('Cart ID (increment): $cartId');
    _updateCartItemQuantity(cartId, _items[index]['quantity'], userId, ukuran);
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_items[index]['quantity'] > 1) {
        _items[index]['quantity']--;
        int cartId = _items[index]['id'];
        int userId = _items[index]['userId'];
        String ukuran = _items[index]['ukuran'];
        print('Cart ID (decrement): $cartId');
        _updateCartItemQuantity(
            cartId, _items[index]['quantity'], userId, ukuran);
      }
    });
  }

  int _calculateTotalPrice() {
    int total = 0;
    for (var item in _items) {
      if (item['isSelected'] == true) {
        // Only include selected items
        final produkSepatu = item['produkSepatu'];
        final harga = produkSepatu != null
            ? (produkSepatu['harga'] as num).toInt()
            : 0; // Cast here
        final quantity =
            (item['quantity'] ?? 0) as int; // Ensure this is an int
        total += harga * quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Keranjang',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Set the font weight to bold
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing; // Toggle editing mode
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Pusatkan ikon dan teks secara horizontal
                children: [
                  Icon(
                    Icons.location_on, // Ikon lokasi
                    color: Colors.red, // Warna ikon
                  ),
                  SizedBox(width: 8), // Jarak antara ikon dan teks
                  Text(
                    _address ??
                        "Loading address...", // Tampilkan alamat di sini
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
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
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    final produkSepatu = item['produkSepatu'];
                                    final harga = produkSepatu != null
                                        ? produkSepatu['harga']
                                        : 0;
                                    final quantity = item['quantity'] ?? 0;
                                    final totalPrice = harga * quantity;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value:
                                                  item['isSelected'] ?? false,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  item['isSelected'] = value;
                                                });
                                              },
                                            ),
                                            produkSepatu != null &&
                                                    produkSepatu['image'] !=
                                                        null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      produkSepatu['image'],
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                    ),
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
                                                        ? produkSepatu[
                                                            'nama_sepatu']
                                                        : 'Unknown Product',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    formatRupiah(totalPrice),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!_isEditing)
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.remove),
                                                    onPressed: () {
                                                      _decrementQuantity(index);
                                                    },
                                                  ),
                                                  Text(item['quantity']
                                                      .toString()),
                                                  IconButton(
                                                    icon: Icon(Icons.add),
                                                    onPressed: () {
                                                      _incrementQuantity(index);
                                                    },
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
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 100, // Set your desired height for the BottomAppBar
          child: BottomAppBar(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _isEditing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Checkbox(
                          value: _items.every((item) =>
                              item['isSelected'] == true), // Select All
                          onChanged: (bool? value) {
                            setState(() {
                              for (var item in _items) {
                                item['isSelected'] = value;
                              }
                            });
                          },
                        ),
                        Text(
                          'Select All',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _items
                                    .any((item) => item['isSelected'] == true)
                                ? _deleteSelectedItems // Call delete function
                                : null, // Disable if no items selected
                            child: Text('Hapus'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${formatRupiah(_calculateTotalPrice())}',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF001F3F),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _items
                                    .any((item) => item['isSelected'] == true)
                                ? () {
                                    List<dynamic> selectedItems = _items
                                        .where((item) =>
                                            item['isSelected'] == true)
                                        .toList();

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PaymentScreen(items: selectedItems),
                                      ),
                                    );
                                  }
                                : null, // Disable button if no items selected
                            child: Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
