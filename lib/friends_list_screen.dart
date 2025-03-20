import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning_eng/main.dart';
import 'user_profile_screen.dart'; // ChatScreen yerine profil ekranını import ediyoruz.

class FriendsListScreen extends StatefulWidget {
  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Arkadaşlar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: isDarkMode ? Colors.black87 : Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDarkMode ? Colors.black87 : Colors.deepPurpleAccent,
              isDarkMode ? Colors.grey[850]! : Colors.purpleAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final friends = snapshot.data!.docs;

            if (friends.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz arkadaş eklenmedi.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friendData = friends[index];
                final friendId = friendData['userId'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const ListTile(title: Text('Yükleniyor...'));
                    }

                    final user = userSnapshot.data;
                    final friendEmail = user!['email'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Text(
                            friendEmail[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          friendEmail,
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete,
                              color: isDarkMode
                                  ? Colors.orangeAccent
                                  : Colors.black),
                          onPressed: () async {
                            bool? confirmDelete =
                                await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Arkadaşı Sil'),
                                content: const Text(
                                    'Bu arkadaşı silmek istediğinize emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context)
                                            .pop(false),
                                    child: const Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context)
                                            .pop(true),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true) {
                              try {
                                // Arkadaşı her iki kullanıcıdan sil
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .collection('friends')
                                    .doc(friendId)
                                    .delete();

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(friendId)
                                    .collection('friends')
                                    .doc(currentUserId)
                                    .delete();

                                scaffoldMessengerKey.currentState
                                    ?.showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Arkadaş başarıyla silindi!')),
                                );
                              } catch (e) {
                                scaffoldMessengerKey.currentState
                                    ?.showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              }
                            }
                          },
                        ),
                        onTap: () {
                          // Arkadaş profil ekranına yönlendirme
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                currentUserId: currentUserId,
                                viewedUserId: friendId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
