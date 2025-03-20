import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Durum çubuğu için gerekli import

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Durum çubuğunu siyah yap
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.black, // Durum çubuğu arka plan rengi
      statusBarIconBrightness: Brightness.light, // Durum çubuğu ikon rengi
    ));
  }

  Future<void> _sendPasswordResetEmail() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );

      Navigator.pop(context); // Return to previous screen
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An error occurred'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back button icon color
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(color: Colors.white), // Title color
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent, // AppBar background color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode ? [Colors.black87, Colors.grey[850]!] : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forgot your password?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color for visibility
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email address to receive a password reset link.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70, // Text color for consistency
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(emailController, 'Email', TextInputType.emailAddress, isDarkMode),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendPasswordResetEmail,
                      child: const Text('Send Password Reset Email'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: Colors.orangeAccent, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType, bool isDarkMode) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.purpleAccent), // Updated label color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: isDarkMode ? Colors.white70 : Colors.purpleAccent), // Border color
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.8), // TextField background color
        prefixIcon: const Icon(Icons.email, color: Colors.purpleAccent), // Icon color
      ),
      keyboardType: keyboardType,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // TextField text color
    );
  }
}
