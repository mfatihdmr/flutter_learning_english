import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'profile_screen.dart';
import 'account_info_screen.dart';
import 'change_password_screen.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true; // Bildirim ayarı

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Container(
          margin: const EdgeInsets.only(left: 16.0),
          child: const Text(
            'Ayarlar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildListTile(
              title: 'Profil',
              subtitle: 'Profilinizi görüntüleyin ve düzenleyin',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            _buildListTile(
              title: 'Hesap Bilgisi',
              subtitle: 'Hesap bilgilerinizi görüntüleyin ve düzenleyin',
              icon: Icons.account_circle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountInfoScreen()),
                );
              },
            ),
            _buildListTile(
              title: 'Şifre Değiştir',
              subtitle: 'Şifrenizi güncelleyin',
              icon: Icons.lock,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              },
            ),
            _buildSwitchListTile(
              title: 'Bildirimleri Aç',
              value: _notificationsEnabled,
              icon: Icons.notifications,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı'
                    ),
                  ),
                );
              },
            ),
            _buildSwitchListTile(
              title: 'Karanlık Tema',
              value: themeProvider.isDarkTheme,
              icon: Icons.brightness_6,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Karanlık tema etkin' : 'Aydınlık tema etkin'
                    ),
                  ),
                );
              },
            ),
            _buildListTile(
              title: 'Hakkında',
              subtitle: 'Bu uygulama hakkında daha fazla bilgi edinin',
              icon: Icons.info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            _buildListTile(
              title: 'Geri Bildirim',
              subtitle: 'Bize geri bildirim gönderin',
              icon: Icons.feedback,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen()),
                );
              },
            ),
            _buildListTile(
              title: 'Hesabı Sil',
              subtitle: 'Hesabınızı kalıcı olarak silin',
              icon: Icons.delete,
              onTap: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[300]),
      ),
      leading: Icon(icon, color: Colors.orangeAccent),
      onTap: onTap,
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orangeAccent,
      secondary: Icon(icon, color: Colors.orangeAccent),
    );
  }

  void _confirmDeleteAccount() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Hesabı Sil',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      );
    },
  );
}


  Future<void> _deleteAccount(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Firestore'daki kullanıcı verisini sil
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      // FirebaseAuth'dan kullanıcıyı sil
      await user.delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap silindi')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hesap silme başarısız: $e')),
      );
    }
  }
}
}
