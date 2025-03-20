import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = FirebaseAuth.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  void _changePassword() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showDialog('Hata', 'Şu anda giriş yapılmış bir kullanıcı yok.');
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showDialog('Hata', 'Yeni şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      _showDialog('Başarılı', 'Şifre başarıyla değiştirildi.');
      Navigator.pop(context); // Önceki ekrana dön
    } catch (e) {
      _showDialog('Hata', 'Şifre değiştirilemedi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Şifre Değiştir',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: isDarkTheme ? Colors.black : Colors.deepPurpleAccent, // Dark mode için siyah
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDarkTheme ? Colors.black : Colors.deepPurpleAccent,
                isDarkTheme ? Colors.grey[900]! : Colors.purpleAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField('Mevcut Şifre', _currentPasswordController, theme),
                      const SizedBox(height: 20),
                      _buildPasswordField('Yeni Şifre', _newPasswordController, theme),
                      const SizedBox(height: 20),
                      _buildPasswordField('Yeni Şifreyi Onayla', _confirmNewPasswordController, theme),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkTheme ? Colors.grey[700] : Colors.orangeAccent, // Koyu tema için gri
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Şifre Değiştir',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, ThemeData theme) {
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
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.deepPurpleAccent),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.lock, color: Colors.deepPurpleAccent),
          ),
          obscureText: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black),
        ),
      ),
    );
  }
}
