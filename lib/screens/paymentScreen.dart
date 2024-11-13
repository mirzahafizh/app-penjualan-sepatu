import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:papb/screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final List<dynamic> items;

  PaymentScreen({required this.items});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _orderId;
  final storage = FlutterSecureStorage();

  String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  int calculateTotalAmount(List<dynamic> items) {
    int total = 0;
    for (var item in items) {
      final produkSepatu = item['produkSepatu'];
      final harga =
          produkSepatu != null ? (produkSepatu['harga'] as num).toInt() : 0;
      final quantity = (item['quantity'] ?? 0) as int;
      total += harga * quantity;
    }
    return total;
  }

  Future<void> _processPayment(BuildContext context) async {
    try {
      final url = Uri.parse('http://10.0.2.2:5000/midtrans/payment');
      final totalAmount = calculateTotalAmount(widget.items);
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _orderId = orderId;
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': totalAmount,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final redirectUrl = data['redirect_url'];

        // Store token securely
        await storage.write(key: 'token', value: token);

        if (kIsWeb) {
          final Uri launchUrl = Uri.parse(redirectUrl);
          if (await canLaunch(launchUrl.toString())) {
            await launch(launchUrl.toString());
          } else {
            throw 'Could not launch $launchUrl';
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebView(
                initialUrl: redirectUrl,
                javascriptMode: JavascriptMode.unrestricted,
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${errorData.toString()}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  Future<void> _saveTransaction(
      int totalAmount, String paymentType, String bank, String status) async {
    String? userId =
        await storage.read(key: 'userId'); // Retrieve userId from storage

    if (userId == null) {
      print('User ID not found');
      return;
    }

    // Assuming widget.items contains only one item for the transaction
    if (widget.items.isEmpty) {
      print('No items found for transaction');
      return;
    }

    // Get the first item from the items list
    final item = widget.items.first;

    // Prepare the product details
    Map<String, dynamic> productDetails = {
      'userId': userId, // Send userId as a string
      'totalAmount': totalAmount, // Total amount
      'paymentMethod': paymentType, // Payment method
      'paymentStatus': status, // Payment status
      'produkSepatuId': item['produkSepatu']['id'], // Product ID
      'ukuran': item['ukuran'], // Size
      'quantity': item['quantity'], // Quantity
    };

    final url = Uri.parse(
        'http://10.0.2.2:5000/api/transaksi'); // Adjust your API endpoint accordingly

    // Log the values before sending the request
    print('Sending transaction: $productDetails');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productDetails), // Send the product details directly
      );

      // Print the response status code and body
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('Transaction saved successfully');
      } else {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          print(
              'Error saving transaction: ${errorData['error'] ?? 'unknown error'}');
        } else {
          print('Error saving transaction: Empty response body');
        }
      }
    } catch (error) {
      print('An error occurred while saving transaction: $error');
    }
  }

  Future<void> checkPaymentStatus() async {
    if (_orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ID is null')),
      );
      return;
    }

    final url =
        Uri.parse('http://10.0.2.2:5000/midtrans/check?orderId=$_orderId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String status = data['transaction_status'] ?? 'unknown';
        String paymentType = data['payment_type'] ?? 'unknown';
        String bank =
            data['va_numbers'] != null && data['va_numbers'].isNotEmpty
                ? data['va_numbers'][0]['bank']
                : 'N/A';

        // Store payment type and bank information securely
        await storage.write(key: 'payment_type', value: paymentType);
        await storage.write(key: 'bank', value: bank);

        // Display payment status, payment method, and bank
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Payment status: $status\nPayment Method: $paymentType\nBank: $bank')),
        );

        if (status == 'settlement') {
          await _saveTransaction(
              calculateTotalAmount(widget.items), paymentType, bank, status);
          await removeItemsFromCart();

          // Navigate to HomeScreen with retrieved details
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment status is: $status')),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error checking payment status: ${errorData['error'] ?? 'unknown error'}'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  Future<void> removeItemsFromCart() async {
    for (var item in widget.items) {
      final id = item['id']; // Adjust this to the actual cart item ID field

      final url = Uri.parse('http://10.0.2.2:5000/api/keranjang/$id');

      try {
        final response = await http.delete(url);

        if (response.statusCode == 200) {
          print('Item with ID $id removed from cart successfully.');
        } else {
          final errorData = jsonDecode(response.body);
          print(
              'Error removing item: ${errorData['error'] ?? 'unknown error'}');
        }
      } catch (error) {
        print('An error occurred while removing item: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Harga: ${formatRupiah(calculateTotalAmount(widget.items))}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Items:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Displaying the list of items with names, sizes, and images
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final imageUrl = item['produkSepatu']
                      ['image']; // Adjust the key to your image URL

                  return ListTile(
                    leading: Image.network(
                      imageUrl,
                      width: 50, // Set a width for the image
                      height: 50, // Set a height for the image
                      fit: BoxFit.cover, // Maintain the aspect ratio
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons
                            .error); // Display an error icon if the image fails to load
                      },
                    ),
                    title: Text(item['produkSepatu']['nama_sepatu'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Size: ${item['ukuran']}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      'Qty: ${item['quantity']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 100, // Set your desired height here
        decoration: BoxDecoration(
          color: Colors.white, // Set the background color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Shadow color
              spreadRadius: 7, // Spread radius of the shadow
              blurRadius: 10, // Blur radius of the shadow
              offset: Offset(0, 5), // Changes the position of the shadow (x, y)
            ),
          ],
        ),
        child: BottomAppBar(
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the entire row
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Center items vertically in the column
                children: [
                  IconButton(
                    icon: Icon(Icons.payment),
                    onPressed: () {
                      _processPayment(context);
                    },
                  ),
                  Text('Process Payment',
                      style: TextStyle(
                          fontWeight: FontWeight
                              .bold)), // Optional label for the first button
                ],
              ),
              SizedBox(width: 40), // Space between columns
              Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Center items vertically in the column
                children: [
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      checkPaymentStatus();
                    },
                  ),
                  Text('Check Payment Status',
                      style: TextStyle(
                          fontWeight: FontWeight
                              .bold)), // Optional label for the second button
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
