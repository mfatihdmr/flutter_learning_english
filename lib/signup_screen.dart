import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'home_screen.dart';
import 'forgot_password_screen.dart'; // Gerekliyse ekleyin
import 'package:flutter/services.dart'; // Durum çubuğu için gerekli import

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Durum çubuğunu siyah yap (örneğin: Android için)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.black, // Durum çubuğu arka plan rengi
      statusBarIconBrightness: Brightness.light, // Durum çubuğu ikon rengi
    ));
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showErrorDialog('Resim seçilirken bir hata oluştu: $e');
    }
  }

  Future<void> _signUp() async {
    // Şifreler eşleşmiyorsa hata mesajı göster
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog('Şifreler eşleşmiyor');
      return;
    }

    // Geçerli e-posta formatı kontrolü
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
      _showErrorDialog('Geçersiz e-posta formatı');
      return;
    }

    try {
      // Kullanıcıyı Firebase Authentication ile oluştur
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // E-posta doğrulama e-postası gönder
      await userCredential.user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama e-postası gönderildi. Lütfen gelen kutunuzu kontrol edin.')),
      );

      String? photoURL;

      // Eğer profil resmi seçildiyse, resmi Firebase Storage'a yükle
      if (_imageFile != null) {
        String fileName = path.basename(_imageFile!.path);
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
        await storageRef.putFile(File(_imageFile!.path));
        photoURL = await storageRef.getDownloadURL();
      }

      // Kullanıcı bilgilerini Cloud Firestore'a ekle
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': emailController.text,
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'phone': phoneController.text,
        'photoURL': photoURL,
        'isActive': true, // Yeni eklenen alan: Kullanıcı aktif olarak işaretlendi.
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Kayıt işlemi başarılıysa kullanıcıyı ana ekrana yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            favoriteFlashcards: [],
            favoriteQuizQuestions: [],
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Bir hata oluştu');
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Geri butonunun rengi
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kayıt Ol', style: TextStyle(color: Colors.white)), // AppBar başlık rengi
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black87, Colors.grey[850]!] 
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(firstNameController, 'Ad', isDarkMode: isDarkMode),
              _buildTextField(lastNameController, 'Soyad', isDarkMode: isDarkMode),
              _buildTextField(phoneController, 'Telefon Numarası', keyboardType: TextInputType.phone, isDarkMode: isDarkMode),
              _buildTextField(emailController, 'E-posta', keyboardType: TextInputType.emailAddress, isDarkMode: isDarkMode),
              _buildTextField(passwordController, 'Şifre', obscureText: true, isDarkMode: isDarkMode),
              _buildTextField(confirmPasswordController, 'Şifreyi Onayla', obscureText: true, isDarkMode: isDarkMode),
              const SizedBox(height: 10.0),
              _imageFile == null
                  ? const Text('Resim seçilmedi.', style: TextStyle(color: Colors.grey))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(_imageFile!.path),
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                    ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Profil Resmi Seç'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  backgroundColor: Colors.orangeAccent,
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text('Kayıt Ol'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.orangeAccent,
                  textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, bool isDarkMode = false}) {
    // Burada dilersen her alana farklı prefix icon ekleyebilirsin.
    IconData prefixIcon;
    if (label.toLowerCase().contains('şifre')) {
      prefixIcon = Icons.lock;
    } else if (label.toLowerCase().contains('e-posta')) {
      prefixIcon = Icons.email;
    } else if (label.toLowerCase().contains('telefon')) {
      prefixIcon = Icons.phone;
    } else {
      prefixIcon = Icons.person;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.deepPurpleAccent),
            border: InputBorder.none,
            prefixIcon: Icon(prefixIcon,
                color: isDarkMode ? Colors.white : Colors.deepPurpleAccent),
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
        ),
      ),
    );
  }
}
