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
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  String? userId; // Variable to store userId

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings from secure storage
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Retrieve userId from secure storage
      userId = await _secureStorage.read(key: 'userId');

      String? storedFullName = await _secureStorage.read(key: 'fullName');
      String? storedEmail = await _secureStorage.read(key: 'email');
      if (storedFullName != null) {
        _fullNameController.text =
            storedFullName; // Set initial value for full name
      }
      if (storedEmail != null) {
        _emailController.text = storedEmail; // Set initial value for email
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings')),
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
          'http://localhost:5000/api/users/$userId'; // Update with your API URL
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
        title: Text('Pengaturan Akun'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController, // Added password field
              decoration: InputDecoration(
                labelText: 'Password (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // Hide password input
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
