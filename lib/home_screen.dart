import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_eng/matching_color_screen.dart';
import 'package:learning_eng/favorite_quiz_screen.dart';
import 'package:learning_eng/flashcard_screen.dart';
import 'package:learning_eng/friends_list_screen.dart';
import 'package:learning_eng/hangman_screen.dart';
import 'package:learning_eng/main.dart';
import 'package:learning_eng/matching_animal_screen.dart';
import 'package:learning_eng/matching_month_screen.dart';
import 'package:learning_eng/quiz_screen.dart';
import 'package:learning_eng/favorite_flashcards_screen.dart';
import 'package:learning_eng/calendar_screen.dart';
import 'package:learning_eng/settings_screen.dart';
import 'package:learning_eng/login_screen.dart';
import 'package:learning_eng/chat_screen.dart';
import 'package:learning_eng/user_list_screen.dart';
import 'package:learning_eng/friend_requests_screen.dart';
import 'package:learning_eng/definition_matching_screen.dart';
import 'package:learning_eng/vocabulary_puzzle_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteFlashcards;
  final List<Map<String, dynamic>> favoriteQuizQuestions;

  HomeScreen({
    required this.favoriteFlashcards,
    required this.favoriteQuizQuestions,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> favoriteFlashcards;
  late List<Map<String, dynamic>> favoriteQuizQuestions;

  @override
  void initState() {
    super.initState();
    favoriteFlashcards = widget.favoriteFlashcards;
    favoriteQuizQuestions = widget.favoriteQuizQuestions;
  }

  void updateFavoriteQuizQuestions(List<Map<String, dynamic>> updatedFavorites) {
    setState(() {
      favoriteQuizQuestions = updatedFavorites;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void showGlobalSnackbar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserId = currentUser.uid;
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ana Ekran',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkTheme ? Colors.black : Colors.deepPurpleAccent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _buildDrawerItem(Icons.calendar_today, 'Takvim', CalendarScreen()),
            _buildDrawerItem(Icons.settings, 'Ayarlar', SettingsScreen()),
            _buildDrawerItem(Icons.star, 'Favori Quizler', 
                FavoriteQuizScreen(favoriteQuizQuestions: favoriteQuizQuestions)),
            _buildDrawerItem(Icons.star, 'Favori Kartlar', 
                FavoriteFlashcardsScreen(favoriteFlashcards: favoriteFlashcards)),
            _buildDrawerItem(Icons.chat, 'Sohbet', UsersListScreen()),
            _buildDrawerItem(Icons.group, 'Arkadaş Listesi', FriendsListScreen()),
            _buildDrawerItem(Icons.notifications, 'Arkadaş İstekleri', 
                FriendRequestsScreen(currentUserId: currentUserId)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
                showGlobalSnackbar('Başarıyla çıkış yaptınız.');
              },
            ),
          ],
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Öğrenme Oyunları',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.5,
                    children: <Widget>[
                      _buildGameCard('Flashcard\'lar', FlashcardGame(favoriteFlashcards: favoriteFlashcards), isDarkTheme),
                      _buildGameCard('Quiz', QuizScreen(
                        favoriteQuizQuestions: favoriteQuizQuestions, 
                        onFavoriteUpdate: updateFavoriteQuizQuestions,
                      ), isDarkTheme),
                      _buildGameCard('Renk Eşleştirme', MatchingColorScreen(), isDarkTheme),
                      _buildGameCard('Hayvan Eşleştirme', MatchingAnimalScreen(), isDarkTheme),
                      _buildGameCard('Ay Eşleştirme', MatchingMonthScreen(), isDarkTheme),
                      _buildGameCard('Kelime Karıştırmaca', DefinitionMatchingFromJsonScreen(), isDarkTheme),
                      _buildGameCard('Kelime Bulmaca', VocabularyPuzzleScreen(), isDarkTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }

  Widget _buildGameCard(String title, Widget screen, bool isDarkTheme) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDarkTheme ? Colors.grey[800] : Colors.orangeAccent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
