import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link açılamadı: $url')),
      );
    }
  }

  Future<void> _launchMail(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.SENDTO',
          data: Uri.encodeFull(
              'mailto:muhammetfatihdemr@gmail.com?subject=Destek&body=')
        );
        await intent.launch();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
      }
    } else {
      final Uri mailUri = Uri(
          scheme: 'mailto',
          path: 'muhammetfatihdemr@gmail.com',
          query: 'subject=Destek&body=');
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta uygulaması açılamadı.')),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama yapılamıyor: $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hakkında',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[850]!]
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uygulama Hakkında',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bu uygulama, kullanıcıların İngilizce dil becerilerini etkileşimli oyunlar ve quizler aracılığıyla geliştirmelerine yardımcı olmak için tasarlanmıştır. Flash kartlar, quizler ve kelime oyunları gibi modülleri içermektedir.',
                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Versiyon 1.0.0',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geliştiren: Muhammet Fatih DEMİR',
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _launchMail(context),
                      child: Text(
                        'Destek için bizimle iletişime geçin: muhammetfatihdemr@gmail.com',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Telefon metnini tıklanabilir hale getiriyoruz.
                    InkWell(
                      onTap: () => _launchPhone(context, '5511635965'),
                      child: Text(
                        'Telefon: 5511635965',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _launchURL(
                        context,
                        'https://www.linkedin.com/in/muhammet-fatih-demir-11987522b/',
                      ),
                      child: Text(
                        'LinkedIn: https://www.linkedin.com/in/muhammet-fatih-demir-11987522b/',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _launchURL(
                        context,
                        'https://github.com/mfatihdmr',
                      ),
                      child: Text(
                        'GitHub: https://github.com/mfatihdmr',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Uygulamamızı kullandığınız için teşekkür ederiz!',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
