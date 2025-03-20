import 'package:flutter/material.dart';

class FavoriteQuizScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteQuizQuestions;

  FavoriteQuizScreen({Key? key, required this.favoriteQuizQuestions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group questions by level
    final Map<String, List<Map<String, dynamic>>> categorizedFavorites = {};
    for (var question in favoriteQuizQuestions) {
      final level = question['level'];
      categorizedFavorites.putIfAbsent(level, () => []).add(question);
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Check if dark mode is enabled

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favori Quizler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white), // Search button color
            onPressed: () {
              showSearch(
                context: context,
                delegate: FavoriteQuizSearchDelegate(favoriteQuizQuestions),
              );
            },
          ),
        ],
        backgroundColor: isDarkMode ? Colors.black87 : Colors.deepPurpleAccent, // AppBar background for dark mode
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Set icon color to white
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent],
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
            final questions = categorizedFavorites[level]!;
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
                children: questions.map((question) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4,
                    color: isDarkMode ? Colors.grey[700] : Colors.purple[50], // Child card background color
                    child: ListTile(
                      title: Text(
                        question['question'],
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black, // Text color for question
                        ),
                      ),
                      subtitle: Text(
                        'Doğru Cevap: ${question['correct_answer']}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700], // Subtitle color for dark mode
                        ),
                      ),
                      onTap: () {
                        // Navigate to a details page
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

class FavoriteQuizSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> favoriteQuizQuestions;

  FavoriteQuizSearchDelegate(this.favoriteQuizQuestions);

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
    final List<Map<String, dynamic>> results = favoriteQuizQuestions.where((question) {
      final questionLower = question['question'].toLowerCase();
      return questionLower.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final question = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white, // Card color
          child: ListTile(
            title: Text(question['question'], style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)), // Title color
            subtitle: Text('Doğru Cevap: ${question['correct_answer']}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700])), // Subtitle color
            onTap: () {
              // Actions when tapping on the search result
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = favoriteQuizQuestions.where((question) {
      final questionLower = question['question'].toLowerCase();
      return questionLower.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final question = suggestions[index];
        return ListTile(
          title: Text(question['question'], style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)), // Title color
          onTap: () {
            query = question['question'];
            showResults(context); // Show the search results
          },
        );
      },
    );
  }
}
