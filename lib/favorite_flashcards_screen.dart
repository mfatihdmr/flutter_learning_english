import 'package:flutter/material.dart';

class FavoriteFlashcardsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteFlashcards;

  const FavoriteFlashcardsScreen({Key? key, required this.favoriteFlashcards})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group flashcards by level
    final Map<String, List<Map<String, dynamic>>> categorizedFavorites = {};
    for (var flashcard in favoriteFlashcards) {
      final level = flashcard['level'];
      categorizedFavorites.putIfAbsent(level, () => []).add(flashcard);
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Check if dark mode is enabled

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favori Flashcardlar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Text color white
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white), // Search icon color
            onPressed: () {
              showSearch(
                context: context,
                delegate: FavoriteFlashcardsSearchDelegate(favoriteFlashcards),
              );
            },
          ),
        ],
        backgroundColor: isDarkMode ? Colors.black87 : Colors.deepPurpleAccent, // AppBar background for dark mode
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black87, Colors.grey[850]!] // Dark mode gradient colors
                : [Colors.deepPurpleAccent, Colors.purpleAccent], // Light mode gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: categorizedFavorites.keys.map((level) {
            final flashcards = categorizedFavorites[level]!;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.8), // Card background for dark mode
              child: ExpansionTile(
                leading: const Icon(Icons.star, color: Colors.orangeAccent), // Icon color
                title: Text(
                  'Seviye $level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: isDarkMode ? Colors.white : Colors.deepPurple[800], // Title color for dark mode
                  ),
                ),
                children: flashcards.map((flashcard) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4,
                    color: isDarkMode ? Colors.grey[700] : Colors.purple[50], // Child card background color
                    child: ListTile(
                      title: Text(
                        flashcard['word'],
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black, // Text color for word
                        ),
                      ),
                      subtitle: Text(
                        flashcard['definition'],
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700], // Subtitle color for dark mode
                        ),
                      ),
                      onTap: () {
                        // Navigate to a detail page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FlashcardDetailScreen(flashcard: flashcard),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FavoriteFlashcardsSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> favoriteFlashcards;

  FavoriteFlashcardsSearchDelegate(this.favoriteFlashcards);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white), // Clear button color
        onPressed: () {
          query = ''; // Clear the search field
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white), // Back button color
      onPressed: () {
        close(context, {}); // Close the search screen
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<Map<String, dynamic>> results = favoriteFlashcards.where((flashcard) {
      final wordLower = flashcard['word'].toLowerCase();
      return wordLower.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final flashcard = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white, // Card color
          child: ListTile(
            title: Text(
              flashcard['word'],
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Title color
              ),
            ),
            subtitle: Text(
              flashcard['definition'],
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700], // Subtitle color
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FlashcardDetailScreen(flashcard: flashcard),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = favoriteFlashcards.where((flashcard) {
      final wordLower = flashcard['word'].toLowerCase();
      return wordLower.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final flashcard = suggestions[index];
        return ListTile(
          title: Text(
            flashcard['word'],
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Title color
            ),
          ),
          onTap: () {
            query = flashcard['word'];
            showResults(context); // Show the search results
          },
        );
      },
    );
  }
}

class FlashcardDetailScreen extends StatelessWidget {
  final Map<String, dynamic> flashcard;

  const FlashcardDetailScreen({required this.flashcard});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Check if dark mode is enabled

    return Scaffold(
      appBar: AppBar(
        title: Text(flashcard['word']),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.deepPurpleAccent, // AppBar background for dark mode
        iconTheme: const IconThemeData(color: Colors.white), // Set the icon color to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flashcard['word'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black, // Word color for dark mode
              ),
            ),
            const SizedBox(height: 16),
            Text(
              flashcard['definition'],
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black54, // Definition color for dark mode
              ),
            ),
          ],
        ),
      ),
    );
  }
}
