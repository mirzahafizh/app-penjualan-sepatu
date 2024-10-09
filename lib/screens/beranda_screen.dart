import 'dart:convert'; // Untuk mengkonversi JSON

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../produk.dart'; // Import model Produk

class BerandaScreen extends StatefulWidget {
  @override
  _BerandaScreenState createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<Produk> _produkList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.6:5000/api/produk-sepatu'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _produkList = data.map((item) => Produk.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load produk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _produkList.length,
            itemBuilder: (context, index) {
              final produk = _produkList[index];
              return ListTile(
                title: Text(produk.nama),
                subtitle: Text('Harga: ${produk.harga}'),
                onTap: () {
                  // Aksi ketika produk ditekan
                },
              );
            },
          );
  }
}
