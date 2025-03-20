import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // JSON dosyalarını yüklemek için

class VocabularyPuzzleScreen extends StatefulWidget {
  @override
  _VocabularyPuzzleScreenState createState() => _VocabularyPuzzleScreenState();
}

class _VocabularyPuzzleScreenState extends State<VocabularyPuzzleScreen> {
  Map<String, dynamic>? allCategories; // Tüm kategorileri içeren JSON verisi
  String selectedCategory = "A1"; // Varsayılan kategori

  String? clue;
  String? correctWord;
  List<String> availableLetters =
      []; // Kullanılabilir harfler (kullanılınca listeden çıkar)
  List<String> originalLetters =
      []; // Oyun başındaki harf dizisi (sıfırlama için)
  List<String> userInput = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllWords();
  }

  Future<void> loadAllWords() async {
    try {
      // JSON dosyasını yükle
      final String jsonString =
          await rootBundle.loadString('assets/words.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        allCategories = jsonData;
        isLoading = false;
      });
      loadWordData();
    } catch (e) {
      print("Error loading JSON data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadWordData() async {
    if (allCategories == null || !allCategories!.containsKey(selectedCategory))
      return;
    try {
      final List<dynamic> categoryWords = allCategories![selectedCategory];
      if (categoryWords.isEmpty) {
        setState(() {
          clue = "Bu kategoride kelime bulunamadı.";
          correctWord = "";
          userInput = [];
          availableLetters = [];
          originalLetters = [];
        });
        return;
      }
      final random = Random();
      final wordData = categoryWords[random.nextInt(categoryWords.length)];
      final answerFromJson = wordData['answer'];
      if (answerFromJson == null || answerFromJson.toString().trim().isEmpty) {
        setState(() {
          clue = "Kelime bilgisi eksik.";
          correctWord = "";
          userInput = [];
          availableLetters = [];
          originalLetters = [];
        });
        return;
      }
      setState(() {
        clue = wordData['clue'];
        correctWord = answerFromJson.toString().toUpperCase();
        userInput = List.filled(correctWord!.length, "");
        availableLetters = correctWord!.split('');
        availableLetters.shuffle();
        originalLetters = List.from(availableLetters);
      });
    } catch (e) {
      print("Error loading word data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLetterTap(String letter) {
    setState(() {
      for (int i = 0; i < userInput.length; i++) {
        if (userInput[i] == "") {
          userInput[i] = letter;
          // Kullanılan harfi availableLetters listesinden kaldırıyoruz.
          availableLetters.remove(letter);
          break;
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      if (correctWord != null) {
        userInput = List.filled(correctWord!.length, "");
        // Sıfırlama yapıldığında orijinal harf dizisini geri yüklüyoruz.
        availableLetters = List.from(originalLetters);
      } else {
        userInput = [];
        availableLetters = [];
      }
    });
  }

  void _checkAnswer() {
    if (userInput.join() == correctWord) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tebrikler!'),
          content: const Text('Doğru cevap!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _onClear();
                loadWordData();
              },
              child: const Text('Devam'),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yanlış cevap, tekrar deneyin.')),
      );
    }
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      selectedCategory = newCategory;
    });
    loadWordData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Bulmaca'),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Kategori seçimi için DropdownButton
                    if (allCategories != null)
                      DropdownButton<String>(
                        value: selectedCategory,
                        items: allCategories!.keys
                            .map<DropdownMenuItem<String>>((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category,
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                    const SizedBox(height: 20),
                    // İpucu alanı
                    Text(
                      clue ?? "İpucu yükleniyor...",
                      style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode ? Colors.white : Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Boş kutucuklar (cevap alanı) kısmı: Yatay kaydırma eklendi
                    // Boş kutucuklar (cevap alanı) kısmı: Yatay kaydırma eklendi
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(userInput.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              // Eğer bu kutucukta bir harf varsa, kaldırıp availableLetters listesine ekleyelim.
                              if (userInput[index].isNotEmpty) {
                                String letter = userInput[index];
                                setState(() {
                                  userInput[index] = "";
                                  availableLetters.add(letter);
                                });
                              }
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors
                                    .white, // Kutucuk arka planı açık renk
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[300]!
                                      : Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                userInput[index],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Colors.black, // Metin rengi sabit siyah
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Harf seçenekleri
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: availableLetters.map((letter) {
                        return ElevatedButton(
                          onPressed: () => _onLetterTap(letter),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                          ),
                          child: Text(
                            letter,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // İşlem butonları: Temizle ve Gönder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _onClear,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Temizle'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Gönder'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
