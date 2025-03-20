import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

class FlashcardGame extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteFlashcards;

  FlashcardGame({required this.favoriteFlashcards});

  @override
  _FlashcardGameState createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<FlashcardGame> {
  List<Map<String, dynamic>> words = [];
  String selectedLevel = "A1";
  List<Map<String, dynamic>> filteredWords = [];
  bool isLoading = true;

  // Pagination variables
  int currentPage = 0;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  void loadWords() async {
    try {
      String data =
          await DefaultAssetBundle.of(context).loadString('assets/data.json');
      List<dynamic> decodedWords = json.decode(data)['words'];
      setState(() {
        words = decodedWords
            .map((word) => {
                  'word': word['word'] as String,
                  'definition': word['definition'] as String,
                  'level': word['level'] as String,
                  'showTranslation': false,
                })
            .toList();
        updateFilteredWords();
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading words: $error')),
      );
    }
  }

  void addToFavorites(Map<String, dynamic> flashcard) {
    if (!widget.favoriteFlashcards
        .any((favorite) => favorite['word'] == flashcard['word'])) {
      setState(() {
        widget.favoriteFlashcards.add(flashcard);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${flashcard['word']} favorilere eklendi!')),
        );
      });
    }
  }

  void updateFilteredWords() {
    setState(() {
      filteredWords =
          words.where((word) => word['level'] == selectedLevel).toList();
      filteredWords.shuffle();
      currentPage = 0; // Seviye değiştiğinde sayfayı sıfırla.
    });
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _nextPage() {
    if ((currentPage + 1) * itemsPerPage < filteredWords.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sayfalama için geçerli kelime alt listesi:
    final int startIndex = currentPage * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage) > filteredWords.length
        ? filteredWords.length
        : (startIndex + itemsPerPage);
    final List<Map<String, dynamic>> paginatedWords =
        filteredWords.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flashcard Oyunu',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.deepPurpleAccent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.brightness == Brightness.dark
                      ? [Colors.black, Colors.grey[900]!]
                      : [Colors.deepPurpleAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Seviye seçimi için DropdownButton
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      value: selectedLevel,
                      items: ["A1", "A2", "B1", "B2"].map((String level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedLevel = newValue!;
                          updateFilteredWords();
                        });
                      },
                      isExpanded: true,
                      dropdownColor: Colors.deepPurpleAccent,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ),
                  ),
                  // Kelimelerin gösterildiği GridView
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: paginatedWords.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            FlipCard(
                              direction: FlipDirection.HORIZONTAL,
                              flipOnTouch: true,
                              front: _buildCardSide(
                                  paginatedWords[index]['word'] as String, theme),
                              back: _buildCardSide(
                                  paginatedWords[index]['definition'] as String,
                                  theme),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(
                                  Icons.star,
                                  color: widget.favoriteFlashcards.any((favorite) =>
                                          favorite['word'] ==
                                          paginatedWords[index]['word'])
                                      ? Colors.orangeAccent
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (widget.favoriteFlashcards.any((favorite) =>
                                        favorite['word'] ==
                                        paginatedWords[index]['word'])) {
                                      widget.favoriteFlashcards.removeWhere(
                                          (favorite) =>
                                              favorite['word'] ==
                                              paginatedWords[index]['word']);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${paginatedWords[index]['word']} favorilerden çıkarıldı!')),
                                      );
                                    } else {
                                      addToFavorites(paginatedWords[index]);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Sayfalama Kontrolleri (Önceki / Sonraki)
                  if (filteredWords.length > itemsPerPage)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentPage > 0)
                            ElevatedButton(
                              onPressed: _previousPage,
                              child: const Text('Önceki'),
                            ),
                          const SizedBox(width: 20),
                          if ((currentPage + 1) * itemsPerPage < filteredWords.length)
                            ElevatedButton(
                              onPressed: _nextPage,
                              child: const Text('Sonraki'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCardSide(String text, ThemeData theme) {
    return Card(
      elevation: 8.0,
      margin: const EdgeInsets.all(10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [Colors.black87, Colors.black54]
                : [Colors.deepPurple.shade100, Colors.deepPurple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.deepPurple[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
