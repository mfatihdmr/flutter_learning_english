import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Tema yönetimi için ThemeProvider

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController(); // Biyografi için kontrolcü

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
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userData = userData;
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _bioController.text = userData['bio'] ?? ''; // Biyografi alanı
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

  Future<void> _updateUserData() async {
    try {
      if (_user != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'bio': _bioController.text, // Biyografi güncellemesi
        });

        await _user?.updateEmail(_emailController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgiler güncellendi!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncellenirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: isDarkTheme
            ? Colors.black
            : theme.appBarTheme.backgroundColor ?? Colors.deepPurpleAccent,
        centerTitle: true,
        iconTheme:
            theme.appBarTheme.iconTheme ?? const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkTheme
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: _userData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _userData?['photoURL'] != null
                        ? CircleAvatar(
                            radius: 55.0,
                            backgroundImage:
                                NetworkImage(_userData!['photoURL']),
                            backgroundColor: theme.colorScheme.surface,
                          )
                        : CircleAvatar(
                            radius: 55.0,
                            backgroundColor: theme.colorScheme.surface,
                            child: Icon(Icons.person,
                                size: 55, color: theme.iconTheme.color),
                          ),
                    const SizedBox(height: 20),
                    _buildTextField('İsim', _firstNameController, theme),
                    const SizedBox(height: 10),
                    _buildTextField('Soyisim', _lastNameController, theme),
                    const SizedBox(height: 10),
                    _buildTextField('E-posta', _emailController, theme,
                        TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _buildTextField('Telefon Numarası', _phoneController, theme,
                        TextInputType.phone),
                    const SizedBox(height: 10),
                    // Yeni Biyografi Alanı
                    _buildTextField('Biyografi', _bioController, theme,
                        TextInputType.multiline),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkTheme
                            ? theme.colorScheme.secondary
                            : Colors.orangeAccent,
                      ),
                      child: Text('Güncelle',
                          style: TextStyle(
                              color: theme.colorScheme.onSecondary)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      ThemeData theme,
      [TextInputType keyboardType = TextInputType.text]) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: theme.cardColor.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: keyboardType == TextInputType.multiline ? null : 1,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: theme.primaryColor),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
