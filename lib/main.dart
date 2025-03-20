import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

// Global ScaffoldMessenger key tanımlandı.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Flutter Demo',
      scaffoldMessengerKey: scaffoldMessengerKey, // Global key burada ekleniyor.
      theme: themeProvider.getTheme(), // Aydınlık tema
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        // Diğer karanlık tema özelleştirmelerini ekleyin.
      ),
      themeMode: themeProvider.themeMode, // Tema modunu ayarla.
      home: const LoginScreen(),
    );
  }
}
