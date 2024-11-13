import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'NewProductListScreen.dart';
import 'PopularProductListScreen.dart';
import 'product_detail_screen.dart';
import 'search_result_screen.dart';

class BerandaScreen extends StatefulWidget {
  BerandaScreen();

  @override
  _BerandaScreenState createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  List<Produk> _produkList = [];
  List<Produk> _popularProducts = []; // List to hold popular products
  bool _isLoading = true;
  String _fullName = '';
  int? _userId;
  String? _token;
  String _selectedCategory = 'all'; // New variable to store selected category

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchProduk();
    fetchPopularProducts(); // Fetch popular products
  }

  Future<void> _loadUserData() async {
    _fullName =
        await _secureStorage.read(key: 'fullName') ?? 'User'; // Load full name
    _userId = int.tryParse(
        await _secureStorage.read(key: 'userId') ?? '0'); // Load user ID
    _token = await _secureStorage.read(key: 'token'); // Load token
    setState(() {});
  }

  Future<void> fetchProduk() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/produk-sepatu'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _produkList = data.map((item) => Produk.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        _handleError(
            'Failed to load produk. Status code: ${response.statusCode}');
      }
    } catch (error) {
      _handleError('Error fetching produk: $error');
    }
  }

  Future<void> fetchPopularProducts() async {
    // Simulate fetching popular products; replace with actual API call if needed
    try {
      // Assuming you have an API endpoint to fetch popular products
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/produk-sepatu'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _popularProducts = data.map((item) => Produk.fromJson(item)).toList();
        });
      } else {
        _handleError(
            'Failed to load popular products. Status code: ${response.statusCode}');
      }
    } catch (error) {
      _handleError('Error fetching popular products: $error');
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to handle category selection
  void _selectCategory(String category) {
    setState(() {
      // Toggle category selection
      if (_selectedCategory == category) {
        _selectedCategory = 'all'; // Set to default value when clicked again
      } else {
        _selectedCategory = category; // Set selected category
      }

      // Navigate to SearchResultsScreen with the selected category
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchResultsScreen(searchQuery: _selectedCategory),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Add SingleChildScrollView
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Add app name above category menu
            Padding(
              padding:
                  const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
              child: Align(
                alignment: Alignment.center, // Center the text horizontally
                child: Text(
                  'SneakPeak', // App name
                  style: TextStyle(
                    fontSize: 24, // Increase font size for better visibility
                    fontWeight: FontWeight.bold, // Bold font for emphasis
                    letterSpacing: 1.5, // Add letter spacing for a modern look
                    color: Color(
                        0xFF001F3F), // Dark blue color or any preferred color
                    fontFamily:
                        'Courier', // You can change this to any available font family
                  ),
                ),
              ),
            ),
            SizedBox(height: 16), // Space between app name and category menu
            _buildCategoryMenu(), // Menu horizontal untuk kategori
            SizedBox(
                height:
                    16), // Jarak antara menu kategori dan judul "New Product"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft, // Rata kiri untuk judul
                child: Text(
                  'Baru',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 8), // Jarak kecil antara judul dan grid produk
            SizedBox(
              height: 200, // Set your desired height for New Product section
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildProductGrid(),
            ),
            SizedBox(
                height: 16), // Jarak antara grid produk baru dan produk populer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft, // Rata kiri untuk judul
                child: Text(
                  'Populer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
                height: 8), // Jarak kecil antara judul dan grid produk populer
            SizedBox(
              height:
                  200, // Set your desired height for Popular Products section
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildPopularProductsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for horizontal category menu
  Widget _buildCategoryMenu() {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0), // Add top padding
      child: Container(
        height: 100,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center alignment
              children: [
                _buildCategoryItem('Running', 'assets/category/sport.png'),
                SizedBox(width: 16), // Space between items
                _buildCategoryItem('Sneakers', 'assets/category/sneakers.png'),
                SizedBox(width: 16),
                _buildCategoryItem('Formal', 'assets/category/formal.png'),
                SizedBox(width: 16),
                _buildCategoryItem('Sandals', 'assets/category/sandal.png'),
                SizedBox(width: 16),
                _buildCategoryItem('Kets', 'assets/category/kets.png'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget for each category item
  Widget _buildCategoryItem(String category, String assetPath) {
    return GestureDetector(
      onTap: () {
        _selectCategory(category);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 0.0), // Add horizontal padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use Image.asset instead of Icon
            Image.asset(
              assetPath,
              width: 80, // Adjust width
              height: 60, // Adjust height
              color: _selectedCategory == category
                  ? Colors.black
                  : Colors.black, // Change color based on selection
            ),
            SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                fontFamily: 'Courier', // Set to a monospace font
                fontSize: 16, // Adjust font size
                color:
                    _selectedCategory == category ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold, // Normal font weight
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    // Filter by category
    List<Produk> filteredList = _produkList.where((produk) {
      bool matchesCategory = _selectedCategory == 'all' ||
          produk.category
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase());
      return matchesCategory; // Only filter by category
    }).toList();

    // Sort the list by id to get the newest products (assuming higher id means newer)
    filteredList.sort((a, b) => b.id.compareTo(a.id));

    // Limit to the first 4 products
    List<Produk> newestProducts = filteredList.take(4).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal, // Set to horizontal scrolling
      itemCount:
          newestProducts.length + 1, // Tambah 1 untuk tombol "Lihat Lainnya"
      itemBuilder: (context, index) {
        if (index == newestProducts.length) {
          // Render tombol dengan hanya ikon
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductListScreen(), // Menuju halaman baru
                ),
              );
            },
            child: Container(
              width: 60, // Sesuaikan ukuran tombol untuk hanya menampung ikon
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward, // Ikon panah ke depan
                  color: Colors.black,
                  size: 24, // Sesuaikan ukuran ikon
                ),
              ),
            ),
          );
        } else {
          final produk = newestProducts[index];
          return _buildProductCard(produk);
        }
      },
    );
  }

  Widget _buildLainnyaButton() {
    return Container(
      width: 60, // Sesuaikan lebar agar sesuai dengan layout
      margin: EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          // Handle aksi ketika tombol ditekan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PopularProductScreen(), // Ganti dengan PopularProductScreen
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_forward, // Hanya ikon panah
              color: Colors.black,
              size: 24, // Sesuaikan ukuran ikon
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularProductsGrid() {
    // Sort the popular products by rating in descending order and limit to the first 4
    List<Produk> limitedPopularProducts = _popularProducts
        .where((produk) =>
            produk.rating > 3) // Ensure we only consider products with a rating
        .toList()
      ..sort((a, b) =>
          b.rating.compareTo(a.rating)) // Sort by rating in descending order
      ..take(4); // Limit to the first 4 products

    return Container(
      height: 200, // Set a fixed height for popular products
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Set to horizontal scrolling
        itemCount:
            limitedPopularProducts.length + 1, // Add 1 for the "Lainnya" button
        itemBuilder: (context, index) {
          if (index == limitedPopularProducts.length) {
            // This is the last item, the button
            return _buildLainnyaButton();
          }
          final produk = limitedPopularProducts[index];
          return _buildProductCard(produk);
        },
      ),
    );
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
        width: 200, // Set a fixed width for horizontal display
        margin: EdgeInsets.all(8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    produk.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                produk.namaSepatu,
                style: TextStyle(
                  fontFamily: 'Courier', // Set to a monospace font
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Rp ${produk.harga.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Courier', // Set to a monospace font
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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
  final String category; // Add this field

  Produk({
    required this.id,
    required this.ukuran,
    required this.rating,
    required this.namaSepatu,
    required this.image,
    required this.harga,
    required this.diskon,
    required this.deskripsi,
    required this.category, // Include category in the constructor
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
      category:
          json['tipe_sepatu'] ?? 'Uncategorized', // Parse category from JSON
    );
  }
}
