import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'favorite_quiz_screen.dart';

class QuizScreen extends StatefulWidget {
  List<Map<String, dynamic>> favoriteQuizQuestions;
  final void Function(List<Map<String, dynamic>>) onFavoriteUpdate; // Callback function

  QuizScreen({
    Key? key,
    required this.favoriteQuizQuestions,
    required this.onFavoriteUpdate,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Tüm sorular
  List<Map<String, dynamic>> quizWords = [];
  // Seviye filtrelenmiş tüm sorular
  List<Map<String, dynamic>> filteredQuizWords = [];
  // Mevcut sayfada gösterilecek sorular (10'ar)
  List<Map<String, dynamic>> currentItems = [];
  
  int currentPage = 0;
  final int itemsPerPage = 10;
  // Mevcut sayfadaki soruların indeksi
  int currentQuestionIndex = 0;

  bool answered = false;
  String selectedAnswer = '';
  bool isCorrect = false;
  String selectedLevel = "A1";
  List<String> levels = ["A1", "A2", "B1", "B2"];
  final _random = Random();

  // Zamanlayıcı ve puanlama için değişkenler
  Timer? _timer;
  int remainingTime = 10; // Her soru için 10 saniye
  int score = 0;
  // Bu sayfada doğru cevap sayısı
  int pageCorrectCount = 0;

  // Cevap seçenekleri (karıştırılmış hali); build()'da yeniden karıştırılmasını engellemek için state'de saklanır.
  List<String> currentShuffledAnswers = [];

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadWords() async {
    try {
      String data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
      List<dynamic> decodedWords = json.decode(data)['quiz_words'];
      if (!mounted) return;
      setState(() {
        quizWords = decodedWords.map((word) {
          return {
            'question': word['question'] as String,
            'correct_answer': word['correct_answer'] as String,
            'incorrect_answers': List<String>.from(word['incorrect_answers']),
            'level': word['level'] as String,
          };
        }).toList();
      });
      filterWordsByLevel();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Soru yüklenirken bir hata oluştu: $e')),
      );
    }
  }

  void filterWordsByLevel() {
    setState(() {
      filteredQuizWords = quizWords.where((word) => word['level'] == selectedLevel).toList();
      filteredQuizWords.shuffle(_random);
      currentPage = 0;
      currentQuestionIndex = 0;
      answered = false;
      selectedAnswer = '';
      score = 0;
      pageCorrectCount = 0;
    });
    loadCurrentPage();
    startTimer();
  }

  void loadCurrentPage() {
    int start = currentPage * itemsPerPage;
    int end = min(filteredQuizWords.length, start + itemsPerPage);
    setState(() {
      currentItems = filteredQuizWords.sublist(start, end);
    });
    if (currentItems.isNotEmpty) {
      currentShuffledAnswers = getShuffledAnswers(currentItems[currentQuestionIndex]);
    }
  }

  List<String> getShuffledAnswers(Map<String, dynamic> question) {
    List<String> answers = List<String>.from(question['incorrect_answers']);
    answers.add(question['correct_answer']);
    answers.shuffle(_random);
    return answers;
  }

  void answerQuestion(String answer) {
    _timer?.cancel();
    setState(() {
      selectedAnswer = answer;
      answered = true;
      isCorrect = answer == currentItems[currentQuestionIndex]['correct_answer'];
      if (isCorrect) {
        pageCorrectCount++;
        score += remainingTime; // Kalan süre kadar puan ekle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğru!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yanlış! Doğru cevap: ${currentItems[currentQuestionIndex]['correct_answer']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void startTimer() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      remainingTime = 10;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        autoWrongAnswer();
      }
    });
  }

  void autoWrongAnswer() {
    setState(() {
      answered = true;
      isCorrect = false;
      selectedAnswer = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Süre doldu! Doğru cevap: ${currentItems[currentQuestionIndex]['correct_answer']}'),
        backgroundColor: Colors.red,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) nextQuestion();
    });
  }

  void nextQuestion() {
    _timer?.cancel();
    if (currentQuestionIndex + 1 < currentItems.length) {
      // Aynı sayfada sonraki soru varsa
      setState(() {
        currentQuestionIndex++;
        answered = false;
        selectedAnswer = '';
      });
      currentShuffledAnswers = getShuffledAnswers(currentItems[currentQuestionIndex]);
      startTimer();
    } else {
      // Bu sayfa tamamlandı, yani 10 soru bitti
      int totalQuestions = filteredQuizWords.length;
      // Eğer daha sonraki sayfa varsa, önce sayfa özetini göster
      if ((currentPage + 1) * itemsPerPage < totalQuestions) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Sayfa Tamamlandı"),
              content: Text("Bu sayfada $pageCorrectCount doğru cevap verdiniz."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      currentPage++;
                      currentQuestionIndex = 0;
                      answered = false;
                      selectedAnswer = '';
                      pageCorrectCount = 0;
                    });
                    loadCurrentPage();
                    startTimer();
                  },
                  child: const Text("Devam"),
                ),
              ],
            );
          },
        );
      } else {
        // Son sayfa bitti, sonuçları göster
        _showResults();
      }
    }
  }

  void _showResults() {
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Tamamlandı!'),
          content: Text('Toplam Puanınız: $score\nDoğru cevap sayınız: $score / ${filteredQuizWords.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Quiz ekranından çık
              },
              child: const Text('Tamam', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void toggleFavoriteQuestion() {
    Map<String, dynamic> currentQuestion = currentItems[currentQuestionIndex];
    List<Map<String, dynamic>> updatedFavorites = List.from(widget.favoriteQuizQuestions);

    if (updatedFavorites.any((question) => question['question'] == currentQuestion['question'])) {
      updatedFavorites.removeWhere((question) => question['question'] == currentQuestion['question']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru favorilerden kaldırıldı!'), backgroundColor: Colors.orange),
      );
    } else {
      updatedFavorites.add(currentQuestion);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru favorilere eklendi!'), backgroundColor: Colors.orange),
      );
    }
    widget.onFavoriteUpdate(updatedFavorites);
    setState(() {
      widget.favoriteQuizQuestions = updatedFavorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (filteredQuizWords.isEmpty || currentItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Oyunu'),
          backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic> currentQuestion = currentItems[currentQuestionIndex];
    List<String> answers = currentShuffledAnswers;
    bool isFavorite = widget.favoriteQuizQuestions.any(
      (question) => question['question'] == currentQuestion['question']
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Oyunu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: Colors.white),
            onPressed: toggleFavoriteQuestion,
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Zaman ve Puan göstergesi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalan Süre: $remainingTime',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Puan: $score',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // İlerleme çubuğu: Toplam sorulara göre ilerleme
              LinearProgressIndicator(
                value: ((currentPage * itemsPerPage) + currentQuestionIndex + 1) / filteredQuizWords.length,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              // Soru metni
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${(currentPage * itemsPerPage) + currentQuestionIndex + 1}. ${currentQuestion['question']}',
                  style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // Cevap seçenekleri butonları
              for (String answer in answers)
                ElevatedButton(
                  onPressed: answered ? null : () => answerQuestion(answer),
                  child: Text(answer, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.orangeAccent,
                  ),
                ),
              const SizedBox(height: 20),
              if (answered)
                ElevatedButton(
                  onPressed: nextQuestion,
                  child: Text(
                      (currentQuestionIndex + 1 < currentItems.length || ((currentPage + 1) * itemsPerPage < filteredQuizWords.length))
                          ? 'Sonraki Soru'
                          : 'Quiz Tamamla',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.orangeAccent,
                  ),
                ),
              const SizedBox(height: 20),
              // Sayfalama kontrolleri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (currentPage > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentPage--;
                          currentQuestionIndex = 0;
                        });
                        loadCurrentPage();
                        startTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text("Önceki Sayfa"),
                    ),
                  const SizedBox(width: 20),
                  if ((currentPage + 1) * itemsPerPage < filteredQuizWords.length)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentPage++;
                          currentQuestionIndex = 0;
                        });
                        loadCurrentPage();
                        startTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text("Sonraki Sayfa"),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
