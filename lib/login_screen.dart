import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;  // Şifreyi gizlemek için kullanılacak durum
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText; // Şifreyi göster/gizle
    });
  }

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta ve şifreyi girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Hata mesajını sıfırla
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        setState(() {
          _errorMessage = 'E-posta doğrulanmadı. Doğrulama e-postası gönderildi.';
        });
        return;
      }

      // Save credentials if "Remember Me" is selected
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('email', emailController.text);
        await prefs.setString('password', passwordController.text);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            favoriteFlashcards: [],
            favoriteQuizQuestions: [],
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        setState(() {
          _errorMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
        });
      } else {
        setState(() {
          _errorMessage = e.message ?? 'Bir hata oluştu';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu';
      });
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
        title: const Text(
          'Giriş',
          style: TextStyle(color: Colors.white), // Başlık rengi beyaz
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.deepPurpleAccent, // AppBar color based on theme
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode ? [Colors.black, Colors.grey[800]!] : [Colors.deepPurpleAccent, Colors.purpleAccent], // Gradient colors based on theme
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max, // Fill available height
          children: [
            const Text(
              'Hoşgeldiniz!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Devam etmek için giriş yapın',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Expanded( // Use Expanded to take up remaining space
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(emailController, 'E-posta', TextInputType.emailAddress, false, isDarkMode),
                    const SizedBox(height: 20),
                    _buildTextField(passwordController, 'Şifre', TextInputType.text, _obscureText, isDarkMode),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          activeColor: isDarkMode ? Colors.orange : Colors.deepPurpleAccent, // Checkbox color based on theme
                        ),
                        const Text('Beni Hatırla', style: TextStyle(color: Colors.white)), // Text color
                      ],
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              child: const Text('Giriş Yap'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                textStyle: const TextStyle(fontSize: 18),
                                backgroundColor: Colors.orangeAccent, // Button color
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Hesabınız yok mu? Kayıt Olun',
                        style: TextStyle(fontSize: 16, color: Colors.white), // Text color
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Şifremi Unuttum?',
                        style: TextStyle(fontSize: 16, color: Colors.white), // Text color
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType, bool obscureText, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.purpleAccent[100]), // Label color based on theme
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: isDarkMode ? Colors.white70 : Colors.purpleAccent[100]!), // Border color based on theme
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.8), // TextField background color
          suffixIcon: label == 'Şifre' ? IconButton( // Sadece şifre alanına göz simgesi ekle
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: isDarkMode ? Colors.white : Colors.purpleAccent[100],
            ),
            onPressed: _togglePasswordVisibility,
          ) : null,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // Text color
      ),
    );
  }
}
