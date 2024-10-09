import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransPaymentPage extends StatelessWidget {
  final String snapToken;

  MidtransPaymentPage({required this.snapToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: WebView(
        initialUrl:
            'https://app.sandbox.midtrans.com/snap/v1/transaction/$snapToken',
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (String url) {
          // Handle payment success or failure here based on the URL
          if (url.contains('success')) {
            // Payment successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Successful!')),
            );
            Navigator.pop(context); // Navigate back
          } else if (url.contains('failure')) {
            // Payment failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Failed!')),
            );
            Navigator.pop(context); // Navigate back
          }
        },
      ),
    );
  }
}
