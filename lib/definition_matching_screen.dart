import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DefinitionMatchingFromJsonScreen extends StatefulWidget {
  @override
  _DefinitionMatchingFromJsonScreenState createState() => _DefinitionMatchingFromJsonScreenState();
}

class _DefinitionMatchingFromJsonScreenState extends State<DefinitionMatchingFromJsonScreen> {
  Map<String, dynamic>? allCategories;
  String selectedCategory = "A1";
  List<dynamic> items = []; // Seçilen kategorideki tüm kelime verileri

  // Sayfalama için:
  final int itemsPerPage = 10;
  int currentPage = 0;

  // Oyun için geçerli sayfadaki veriler:
  List<dynamic> currentItems = [];
  List<String> availableWords = [];
  late List<String?> matchedWords;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllWords();
  }

  Future<void> loadAllWords() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/words.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        allCategories = jsonData;
        isLoading = false;
      });
      _resetPaginationAndLoad();
    } catch (e) {
      print("Error loading JSON data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _resetPaginationAndLoad() {
    currentPage = 0;
    loadCategoryItems();
  }

  void loadCategoryItems() {
    if (allCategories == null || !allCategories!.containsKey(selectedCategory)) return;
    items = allCategories![selectedCategory];
    int start = currentPage * itemsPerPage;
    int end = min(items.length, start + itemsPerPage);
    setState(() {
      currentItems = items.sublist(start, end);
      matchedWords = List<String?>.filled(currentItems.length, null);
      availableWords = currentItems
          .map<String>((item) => item['answer'].toString().toUpperCase())
          .toList();
      availableWords.shuffle(Random());
    });
  }

  void _onWordDropped(String word, int index) {
    setState(() {
      if (matchedWords[index] != null) {
        availableWords.add(matchedWords[index]!);
      }
      matchedWords[index] = word;
      availableWords.remove(word);
    });
  }

  void _checkAnswers() {
    int correctCount = 0;
    for (int i = 0; i < currentItems.length; i++) {
      if (matchedWords[i] == currentItems[i]['answer'].toString().toUpperCase()) {
        correctCount++;
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sonuç"),
        content: Text("Doğru eşleştirme sayısı: $correctCount / ${currentItems.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Tamam"),
          )
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      loadCategoryItems();
    });
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      selectedCategory = newCategory;
    });
    _resetPaginationAndLoad();
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      loadCategoryItems();
    }
  }

  void _goToNextPage() {
    if ((currentPage + 1) * itemsPerPage < items.length) {
      setState(() {
        currentPage++;
      });
      loadCategoryItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanım Eşleştirme Oyunu"),
        backgroundColor: isDark ? Colors.black : Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
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
                    // Kategori seçimi
                    if (allCategories != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: allCategories!.keys.map<DropdownMenuItem<String>>((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category, style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                            );
                          }).toList(),
                          onChanged: _onCategoryChanged,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "Tanım kartlarının altındaki doğru kelimeyi sürükleyip bırakın.",
                      style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Tanım kartları (ListView)
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentItems.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentItems[index]['clue'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DragTarget<String>(
                                    onAccept: (word) => _onWordDropped(word, index),
                                    builder: (context, candidateData, rejectedData) {
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue, width: 2),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          matchedWords[index] ?? "Kelime ekleyin",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Kullanılabilir kelimeler Wrap ile
                    Text("Kelimeler", style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: availableWords.map((word) {
                        return Draggable<String>(
                          data: word,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(word, style: const TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(word, style: const TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(word, style: const TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Sayfalama Kontrolleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentPage > 0)
                          ElevatedButton(
                            onPressed: _goToPreviousPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text("Önceki"),
                          ),
                        const SizedBox(width: 20),
                        if ((currentPage + 1) * itemsPerPage < items.length)
                          ElevatedButton(
                            onPressed: _goToNextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text("Sonraki"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Kontrol ve Sıfırla butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _checkAnswers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Kontrol Et"),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _resetGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Sıfırla"),
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
