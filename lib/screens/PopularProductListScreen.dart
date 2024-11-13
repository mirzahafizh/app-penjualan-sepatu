import 'dart:convert'; // Untuk mengkonversi JSON

import 'package:flutter/material.dart'; // Komponen UI dasar Flutter
import 'package:http/http.dart' as http; // Untuk melakukan HTTP request

import 'product_detail_screen.dart'; // Ganti dengan path yang sesuai

class PopularProductScreen extends StatefulWidget {
  @override
  _PopularProductScreenState createState() => _PopularProductScreenState();
}

class _PopularProductScreenState extends State<PopularProductScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Produk> _popularProducts = [];
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialPopularProducts();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadInitialPopularProducts() async {
    await _fetchPopularProducts(page: _currentPage);
  }

  Future<void> _fetchPopularProducts({required int page}) async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/produk-sepatu?page=$page'), // Ganti dengan endpoint untuk produk populer
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Filter produk dengan rating 3 ke atas
        List<Produk> fetchedProducts = data
            .map((item) => Produk.fromJson(item))
            .where((produk) =>
                produk.rating >=
                3) // Hanya ambil produk dengan rating 3 ke atas
            .toList();

        setState(() {
          _popularProducts.addAll(fetchedProducts);
          _isLoadingMore = false;
        });
      } else {
        _handleError(
            'Failed to load more popular products. Status code: ${response.statusCode}');
      }
    } catch (error) {
      _handleError('Error fetching more popular products: $error');
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _currentPage++;
      _fetchPopularProducts(page: _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produk Populer'),
      ),
      body: _popularProducts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Jumlah kolom dalam grid
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.75, // Atur proporsi grid agar sesuai
              ),
              itemCount: _popularProducts.length +
                  1, // Tambah 1 untuk loading indicator
              itemBuilder: (context, index) {
                if (index == _popularProducts.length) {
                  return _isLoadingMore
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(); // Kosong jika tidak sedang loading
                } else {
                  final produk = _popularProducts[index];
                  return _buildProductCard(produk);
                }
              },
              padding: EdgeInsets.all(10.0),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildProductCard(Produk produk) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(id: produk.id),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                produk.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                produk.namaSepatu,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Rp ${produk.harga.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            ),
            // Spacer to push rating to the bottom
            Spacer(),
            // Add a Row for displaying the rating at the bottom
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber, // Color for the star
                    size: 16.0, // Size of the star icon
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    produk.rating.toString(), // Display the rating
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Produk {
  final int id;
  final String ukuran;
  final double rating;
  final String namaSepatu;
  final String image;
  final int harga;
  final int diskon;
  final String deskripsi;
  final String category;

  Produk({
    required this.id,
    required this.ukuran,
    required this.rating,
    required this.namaSepatu,
    required this.image,
    required this.harga,
    required this.diskon,
    required this.deskripsi,
    required this.category,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      ukuran: json['ukuran'] ?? 'Unknown',
      rating: json['rating']?.toDouble() ?? 0.0,
      namaSepatu: json['nama_sepatu'] ?? 'Unknown',
      image: json['image'] ?? '',
      harga: json['harga'],
      diskon: json['diskon'] ?? 0,
      deskripsi: json['deskripsi'] ?? 'No description available',
      category: json['tipe_sepatu'] ?? 'Uncategorized',
    );
  }
}
