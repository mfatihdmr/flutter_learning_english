import 'dart:convert';
import 'package:flutter/material.dart';

class HangmanGame extends StatefulWidget {
  @override
  _HangmanGameState createState() => _HangmanGameState();
}

class _HangmanGameState extends State<HangmanGame> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> words = [];
  String selectedWord = "";
  Set<String> guessedLetters = {};
  int currentQuestionIndex = 0;
  List<Map<String, dynamic>> shuffledWords = [];
  
  String selectedLevel = "A1";
  List<String> levels = ["A1", "A2", "B1", "B2"];
  
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    loadWords();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController!)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void loadWords() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
    setState(() {
      List<dynamic> decodedWords = json.decode(data)['words'];
      words = decodedWords
          .map((word) => {
                'word': word['word'] as String,
                'definition': word['definition'] as String,
                'level': word['level'] as String,
              })
          .toList();
      shuffleWords();
    });
  }

  void shuffleWords() {
    setState(() {
      shuffledWords = words.where((word) => word['level'] == selectedLevel).toList();
      shuffledWords.shuffle();
      selectWord();
    });
  }

  void selectWord() {
    setState(() {
      if (currentQuestionIndex < shuffledWords.length) {
        selectedWord = shuffledWords[currentQuestionIndex]['word']?.toLowerCase() ?? '';
      } else {
        currentQuestionIndex = 0;
        shuffleWords();
      }
    });
  }

  void guessLetter(String letter) {
    setState(() {
      guessedLetters.add(letter);
      if (selectedWord.contains(letter)) {
        _animationController!.reset();
        _animationController!.forward();
      }
      checkGameStatus();
    });
  }

  void checkGameStatus() {
    if (wordGuessed()) {
      resetGame();
      currentQuestionIndex++;
      selectWord();
    }
  }

  bool wordGuessed() {
    for (int i = 0; i < selectedWord.length; i++) {
      if (!guessedLetters.contains(selectedWord[i])) {
        return false;
      }
    }
    return true;
  }

  void resetGame() {
    setState(() {
      guessedLetters.clear();
      _animationController!.reset();
      _animationController!.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dark mode check
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adam Asmaca Oyunu',
          style: TextStyle(color: Colors.white),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: selectedLevel,
                  items: levels.map((String level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedLevel = newValue!;
                      currentQuestionIndex = 0;
                      shuffleWords();
                    });
                  },
                  dropdownColor: isDarkMode ? Colors.black54 : Colors.deepPurple,
                ),
              ),
              Text(
                'Question: ${currentQuestionIndex + 1}',
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20.0),
              Opacity(
                opacity: _animation!.value,
                child: const Text(
                  'Correct!',
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Word: ${getDisplayedWord()}',
                style: const TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20.0),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: List.generate(26, (index) {
                  String letter = String.fromCharCode('a'.codeUnitAt(0) + index);
                  return ElevatedButton(
                    onPressed: guessedLetters.contains(letter)
                        ? null
                        : () => guessLetter(letter),
                    style: ButtonStyle(
                      backgroundColor: guessedLetters.contains(letter)
                          ? MaterialStateProperty.all(isDarkMode ? Colors.grey[800] : Colors.grey)
                          : MaterialStateProperty.all(isDarkMode ? Colors.grey[700] : Colors.orangeAccent),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    child: Text(letter),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getDisplayedWord() {
    String displayedWord = '';
    for (int i = 0; i < selectedWord.length; i++) {
      if (guessedLetters.contains(selectedWord[i])) {
        displayedWord += selectedWord[i];
      } else {
        displayedWord += '_';
      }
      displayedWord += ' ';
    }
    return displayedWord.trim();
  }
}
