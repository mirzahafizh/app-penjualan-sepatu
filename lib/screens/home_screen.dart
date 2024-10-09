import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'keranjang_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  int _currentIndex = 0;
  String? token;
  int? userId;
  String? fullName;
  String? email;
  String? role;
  String _searchQuery = ''; // For storing the search query

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    token = await storage.read(key: 'token');
    userId = int.tryParse(await storage.read(key: 'id') ?? '0');
    fullName = await storage.read(key: 'fullName');
    email = await storage.read(key: 'email');
    role = await storage.read(key: 'role');

    setState(() {}); // Rebuild UI after loading data
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = fullName == null
        ? Center(child: CircularProgressIndicator())
        : _getCurrentScreen();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF001F3F), // Dark blue color
        title: Row(
          children: [
            Text(
              'SneakPeek', // Zash Store text
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 20), // Space between the title and search bar
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query; // Update search query
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(0xFF001F3F), // Dark blue background
        child: bodyContent,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return BerandaScreen(
            searchQuery:
                _searchQuery); // Pass the search query to BerandaScreen
      case 1:
        return KeranjangScreen();
      case 2:
        return WishlistScreen();
      case 3:
        return ProfilScreen();
      default:
        return BerandaScreen(
            searchQuery: _searchQuery); // Default to BerandaScreen
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), label: 'Keranjang'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      unselectedItemColor: Colors.grey,
      selectedItemColor: Colors.black,
      backgroundColor:
          Colors.blue[900], // Dark blue background for BottomNavigationBar
    );
  }
}

class BerandaScreen extends StatefulWidget {
  final String searchQuery;

  BerandaScreen({required this.searchQuery});

  @override
  _BerandaScreenState createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  List<Produk> _produkList = [];
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
      final response = await http
          .get(Uri.parse('http://192.168.1.6:5000/api/produk-sepatu'));

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome, $_fullName!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          _buildCategoryMenu(), // Menu horizontal untuk kategori
          SizedBox(
              height: 16), // Jarak antara menu kategori dan judul "New Product"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft, // Rata kiri untuk judul
              child: Text(
                'New Product',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 8), // Jarak kecil antara judul dan grid produk
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  // Widget for horizontal category menu
  Widget _buildCategoryMenu() {
    return Container(
      height: 100,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Rata tengah
            children: [
              _buildCategoryItem('Running', Icons.directions_run),
              SizedBox(width: 16), // Jarak antar item
              _buildCategoryItem('Sneakers', Icons.sports),
              SizedBox(width: 16),
              _buildCategoryItem('Formal', Icons.mood),
              SizedBox(width: 16),
              _buildCategoryItem('Sandals', Icons.waves),
              SizedBox(width: 16),
              _buildCategoryItem('Kets', Icons.shopping_bag),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for each category item
  Widget _buildCategoryItem(String category, IconData icon) {
    return GestureDetector(
      onTap: () {
        _selectCategory(category);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: _selectedCategory == category ? Colors.blue : Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              color: _selectedCategory == category ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    List<Produk> filteredList = _produkList.where((produk) {
      bool matchesCategory = _selectedCategory == 'all' ||
          produk.category
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase());
      bool matchesSearch = produk.namaSepatu
          .toLowerCase()
          .contains(widget.searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int columns = (width / 150).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: (1 / 1.5),
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final produk = filteredList[index];
            return _buildProductCard(produk);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Produk produk) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              id: produk.id,
            ),
          ),
        );
      },
      child: Container(
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
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                produk.namaSepatu,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${produk.harga}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
