import 'dart:convert';

import 'package:http/http.dart' as http;

class MidtransService {
  final String serverKey =
      'SB-Mid-server-vrjGWm6lbc6SYxZoZUu6i5B4'; // Ganti dengan Server Key dari Midtrans

  Future<http.Response?> createTransaction(int amount, String orderId) async {
    final url = Uri.parse('https://api.sandbox.midtrans.com/v2/charge');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic SB-Mid-server-vrjGWm6lbc6SYxZoZUu6i5B4',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "payment_type": "gopay",
          "transaction_details": {"order_id": orderId, "gross_amount": amount}
        }),
      );

      if (response.statusCode == 201) {
        print('Transaction created successfully');
        return response;
      } else {
        print('Failed to create transaction: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }
}
