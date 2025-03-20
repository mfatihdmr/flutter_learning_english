import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountInfoScreen extends StatefulWidget {
  @override
  _AccountInfoScreenState createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (_user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userData = userData;
          });
        } else {
          setState(() {
            _userData = {};
          });
        }
      }
    } catch (e) {
      setState(() {
        _userData = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hesap Bilgisi',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: isDarkTheme ? Colors.black : (theme.appBarTheme.backgroundColor ?? Colors.deepPurpleAccent), // Black for dark mode
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme ?? const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkTheme
                ? [Colors.black, Colors.grey[850]!] // Darker gradient for dark theme
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: _userData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _userData?['photoURL'] != null
                      ? CircleAvatar(
                          radius: 55.0,
                          backgroundImage: NetworkImage(_userData!['photoURL']),
                          backgroundColor: theme.colorScheme.surface,
                        )
                      : CircleAvatar(
                          radius: 55.0,
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(Icons.person, size: 55, color: theme.iconTheme.color),
                        ),
                  const SizedBox(height: 20),
                  _buildInfoCard('İsim', _userData?['firstName'], theme),
                  _buildInfoCard('Soyisim', _userData?['lastName'], theme),
                  _buildInfoCard('E-posta', _userData?['email'], theme),
                  _buildInfoCard('Telefon Numarası', _userData?['phone'], theme),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String? value, ThemeData theme) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: theme.cardColor.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.iconTheme.color ?? Colors.deepPurpleAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color ?? Colors.deepPurpleAccent,
                    ),
                  ),
                  Text(
                    value ?? 'Yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color ?? Colors.grey[800],
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
