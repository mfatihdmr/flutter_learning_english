import 'dart:convert';
import 'package:flutter/material.dart';

class MatchingAnimalScreen extends StatefulWidget {
  @override
  MatchingAnimalScreenState createState() => MatchingAnimalScreenState();
}

class MatchingAnimalScreenState extends State<MatchingAnimalScreen> {
  List<Map<String, String>> words = [];
  List<String> englishWords = [];
  List<String> turkishWords = [];
  Map<String, String> matchedWords = {};
  int matches = 0;

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    try {
      String data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
      List<dynamic> decodedWords = json.decode(data)['matching_animals'];
      words = decodedWords.map((word) => {
            'english': word['english'] as String,
            'turkish': word['turkish'] as String,
          }).toList();
      englishWords = words.map((word) => word['english']!).toList();
      turkishWords = words.map((word) => word['turkish']!).toList();
      englishWords.shuffle();
      turkishWords.shuffle();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelimeler yüklenirken bir hata oluştu')),
      );
    }
  }

  void matchWords(String english, String turkish) {
    if (words.any((word) => word['english'] == english && word['turkish'] == turkish)) {
      setState(() {
        matchedWords[english] = turkish;
        matches++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$english - $turkish eşleşti!')),
      );

      if (matches == words.length) {
        _showCompletionDialog();
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tebrikler!', style: TextStyle(color: Colors.deepPurple)),
          content: const Text('Tüm eşleşmeleri tamamladınız!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  matchedWords.clear();
                  matches = 0;
                  englishWords.shuffle();
                  turkishWords.shuffle();
                });
              },
              child: const Text('Tekrar Oyna', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent, // Yeni oyun butonunda turuncu yerine mor
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hayvan Eşleştirme Oyunu', style: TextStyle(color: Colors.white)),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.black, Colors.grey[850]!]
                      : [Colors.deepPurpleAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Eşleşmeler: $matches',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4.0,
                        ),
                        itemCount: englishWords.length,
                        itemBuilder: (context, index) {
                          return Draggable<String>(
                            data: englishWords[index],
                            child: matchedWords.containsKey(englishWords[index])
                                ? WordCard(word: englishWords[index], isMatched: true, isDarkMode: isDarkMode)
                                : WordCard(word: englishWords[index], isDarkMode: isDarkMode),
                            feedback: Material(
                              color: Colors.transparent,
                              child: WordCard(word: englishWords[index], isDarkMode: isDarkMode),
                            ),
                            childWhenDragging: WordCard(word: '', isMatched: false, isDarkMode: isDarkMode),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4.0,
                        ),
                        itemCount: turkishWords.length,
                        itemBuilder: (context, index) {
                          return DragTarget<String>(
                            builder: (context, candidateData, rejectedData) {
                              return matchedWords.containsValue(turkishWords[index])
                                  ? WordCard(word: turkishWords[index], isMatched: true, isDarkMode: isDarkMode)
                                  : WordCard(word: turkishWords[index], isDarkMode: isDarkMode);
                            },
                            onWillAccept: (data) => true,
                            onAccept: (data) {
                              matchWords(data, turkishWords[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class WordCard extends StatelessWidget {
  final String word;
  final bool isMatched;
  final bool isDarkMode;

  WordCard({required this.word, this.isMatched = false, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isMatched
            ? Colors.green[300]
            : (isDarkMode ? Colors.grey[800] : Colors.orangeAccent),
        borderRadius: BorderRadius.circular(15), // Kartın köşe yuvarlama
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(2, 2), // Gölgeyi biraz kaydırdım
          ),
        ],
      ),
      margin: const EdgeInsets.all(8.0),
      curve: Curves.easeInOut,
      child: Center(
        child: Text(
          word,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
