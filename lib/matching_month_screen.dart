import 'dart:convert';
import 'package:flutter/material.dart';

class MatchingMonthScreen extends StatefulWidget {
  @override
  MatchingMonthScreenState createState() => MatchingMonthScreenState();
}

class MatchingMonthScreenState extends State<MatchingMonthScreen> {
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

  void loadWords() async {
    String data =
        await DefaultAssetBundle.of(context).loadString('assets/data.json');
    setState(() {
      List<dynamic> decodedWords = json.decode(data)['matching_months'];
      words = decodedWords
          .map((word) => {
                'english': word['english'] as String,
                'turkish': word['turkish'] as String,
              })
          .toList();
      englishWords = words.map((word) => word['english']!).toList();
      turkishWords = words.map((word) => word['turkish']!).toList();
      englishWords.shuffle();
      turkishWords.shuffle();
    });
  }

  void matchWords(String english, String turkish) {
    if (words.any(
        (word) => word['english'] == english && word['turkish'] == turkish)) {
      setState(() {
        matchedWords[english] = turkish;
        matches++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$english - $turkish eşleşti!')),
      );

      // Tüm eşleşmeler tamamlandığında
      if (matches == words.length) {
        _showCompletionDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yanlış eşleşme!')),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tebrikler!'),
          content: const Text('Tüm ayları eşleştirdiniz!'),
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
              child: const Text('Tekrar Oyna',
                  style: TextStyle(color: Colors.white)), // Açık renk
              style: TextButton.styleFrom(
                backgroundColor: Colors.orangeAccent, // Turuncu buton rengi
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark mode check
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayları Eşleştirme Oyunu',
            style: TextStyle(color: Colors.white)), // Açık renk
        backgroundColor:
            isDarkMode ? Colors.black : Colors.deepPurpleAccent, // AppBar color
        iconTheme: const IconThemeData(
            color: Colors.white), // Back button color set to white
      ),
      body: words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          Colors.black,
                          Colors.grey[850]!
                        ] // Update to a consistent dark mode gradient
                      : [
                          Colors.deepPurpleAccent,
                          Colors.purpleAccent
                        ], // Light mode gradient
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
                                ? WordCard(
                                    word: englishWords[index],
                                    isMatched: true,
                                    isDarkMode: isDarkMode)
                                : WordCard(
                                    word: englishWords[index],
                                    isDarkMode: isDarkMode),
                            feedback: Material(
                              color: Colors.transparent,
                              child: WordCard(
                                  word: englishWords[index],
                                  isDarkMode: isDarkMode),
                            ),
                            childWhenDragging: WordCard(
                                word: '',
                                isMatched: false,
                                isDarkMode: isDarkMode),
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
                              return matchedWords
                                      .containsValue(turkishWords[index])
                                  ? WordCard(
                                      word: turkishWords[index],
                                      isMatched: true,
                                      isDarkMode: isDarkMode)
                                  : WordCard(
                                      word: turkishWords[index],
                                      isDarkMode: isDarkMode);
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

  WordCard(
      {required this.word, this.isMatched = false, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isMatched
          ? Colors.green[300]
          : isDarkMode
              ? Colors.grey[800] // Dark mode background for the cards
              : Colors.orangeAccent, // Light mode background
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          word,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Text color for both modes
          ),
        ),
      ),
    );
  }
}
