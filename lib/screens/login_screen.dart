import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:http/http.dart' as http;

import 'home_screen.dart'; // Import HomeScreen
import 'register_screen.dart'; // Import RegisterScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage =
      FlutterSecureStorage(); // Initialize secure storage

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkToken();
  }

  // Check if token exists and auto-login
  Future<void> checkToken() async {
    String? token = await storage.read(key: 'token');
    if (token != null) {
      // Navigate to HomeScreen if token exists without passing additional data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(), // No data passed here
        ),
      );
    } else {
      setState(() {
        isLoading = false; // Stop showing loading screen if no token
      });
    }
  }

  Future<void> login(BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6:5000/api/users/login'), // Your API URL
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    // Print the response for debugging
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}'); // Print the entire response body

    if (response.statusCode == 200) {
      // Handle successful login
      final data = json.decode(response.body);
      final String token = data['token'];
      final user = data['user']; // Get the user object
      final String email = user['email']; // Extract email from user object
      final String fullName =
          user['fullName']; // Extract fullName from user object
      final String role = user['role']; // Extract role from user object
      final String userId =
          user['id'].toString(); // Extract userId and convert to string

      // Store token and user details securely
      await storage.write(key: 'token', value: token);
      await storage.write(key: 'email', value: email);
      await storage.write(key: 'fullName', value: fullName);
      await storage.write(key: 'role', value: role);
      await storage.write(key: 'userId', value: userId); // Store userId

      // Store password securely (temporary storage)
      await storage.write(key: 'password', value: passwordController.text);

      // Navigate to HomeScreen after successful login without passing additional data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(), // No data passed here
        ),
      );
    } else {
      // Handle login error
      print('Login failed: ${response.body}');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Login failed: ${response.body}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Image
              Image.asset(
                'assets/images/Screenshot (35).png', // Make sure this image exists in assets
                height: 250.0,
              ),
              SizedBox(height: 20.0),

              // Welcome text
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10.0),

              // Email input field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.0),

              // Password input field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                obscureText: true,
              ),
              SizedBox(height: 20.0),

              // Login button
              SizedBox(
                width: double.infinity, // Set button width to full width
                child: ElevatedButton(
                  onPressed: () {
                    login(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    backgroundColor: Colors.blueAccent, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.0),

              // Register link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Don\'t have an account? Register here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
