import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilScreen extends StatefulWidget {
  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FlutterSecureStorage storage =
      FlutterSecureStorage(); // Initialize secure storage
  String? fullName;
  String? email;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    fullName = await storage.read(key: 'fullName');
    email = await storage.read(key: 'email');
    role = await storage.read(key: 'role');

    setState(() {}); // Rebuild UI after loading data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color here
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Display user information

            SizedBox(height: 20),
            // Settings Menu
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Pengaturan Akun'),
                    onTap: () {
                      // Navigate to account settings page
                      Navigator.pushNamed(
                        context,
                        '/accountSettings',
                        arguments: {
                          'fullName': fullName,
                          'email': email,
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: Text('History Transaksi'),
                    onTap: () {
                      // Navigate to transaction history page
                      Navigator.pushNamed(context, '/transactionHistory');
                    },
                  ),
                  // Removed admin role-specific menu
                  ListTile(
                    title: Text('Logout'),
                    onTap: () async {
                      // Clear all secure storage
                      await storage.deleteAll();
                      // Navigate back to the login screen
                      Navigator.pushReplacementNamed(context, '/login');
                    },
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
