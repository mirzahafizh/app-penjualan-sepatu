import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AccountSettingsScreen extends StatefulWidget {
  AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // Added password controller
  final TextEditingController _addressController =
      TextEditingController(); // Added address controller
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  String? userId; // Variable to store userId

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load userId from secure storage and fetch user data
  }

  Future<void> _loadUserId() async {
    userId = await _secureStorage.read(key: 'userId');
    if (userId != null) {
      await _fetchUserData(userId!); // Fetch user data after getting userId
    }
  }

  Future<void> _fetchUserData(String id) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Retrieve the authentication token from secure storage
      String? token = await _secureStorage.read(key: 'token');

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/users/$id'), // Update with your API URL
        headers: {
          'Authorization':
              'Bearer $token', // Add token to the Authorization header
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming the response body contains fields 'fullName', 'email', and 'address'
        _fullNameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
      } else {
        // Handle error response from the server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full name cannot be empty')),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve the authentication token from secure storage
      String? token = await _secureStorage.read(key: 'token');

      // Prepare data for the API request
      final url =
          'http://10.0.2.2:5000/api/users/$userId'; // Update with your API URL
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Add token to the Authorization header
        },
        body: jsonEncode({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null, // Include password only if provided
          'address': _addressController.text, // Include address in the request
        }),
      );

      if (response.statusCode == 200) {
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully')),
        );

        // Optionally, navigate back to the profile screen or any other screen
        Navigator.pop(context);
      } else {
        // Handle error response from the server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Akun',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Set the font weight to bold
            )),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold), // Set label to bold
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                  fontWeight: FontWeight.bold), // Set input text to bold
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold), // Set label to bold
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                  fontWeight: FontWeight.bold), // Set input text to bold
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _addressController, // Added address field
              decoration: InputDecoration(
                labelText: 'Alamat',
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold), // Set label to bold
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                  fontWeight: FontWeight.bold), // Set input text to bold
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController, // Added password field
              decoration: InputDecoration(
                labelText: 'Password (optional)',
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold), // Set label to bold
                border: OutlineInputBorder(),
              ),
              obscureText: true, // Hide password input
              style: TextStyle(
                  fontWeight: FontWeight.bold), // Set input text to bold
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Simpan',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold, // Set the font weight to bold
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
