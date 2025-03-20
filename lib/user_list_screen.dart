import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class UsersListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mevcut kullanıcıyı alıyoruz
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserId = currentUser.uid;
    final currentUserEmail = currentUser.email;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kullanıcılar',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        flexibleSpace: Container(
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
        ),
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
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Giriş yapan kullanıcıyı hariç tutarak kullanıcıları filtreleyin
            final users = snapshot.data!.docs
                .where((doc) => doc.id != currentUserId)
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userId = userDoc.id;
                final data = userDoc.data() as Map<String, dynamic>;
                final email = data['email'] ?? 'No Email';
                final firstName = data['firstName'] ?? 'No Name';
                final photoURL = data['photoURL'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoURL != null &&
                              photoURL.toString().isNotEmpty
                          ? NetworkImage(photoURL)
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      email,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      firstName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.person_add,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () async {
                        try {
                          // Arkadaş isteğini "friendRequests" koleksiyonuna ekliyoruz.
                          await FirebaseFirestore.instance
                              .collection('friendRequests')
                              .add({
                            'senderId': currentUserId,
                            'receiverId': userId,
                            'status': 'pending', // pending, accepted, rejected
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('$email\'e arkadaş isteği gönderildi.'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Arkadaş isteği gönderilirken hata: $e'),
                            ),
                          );
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            currentUserId: currentUserId,
                            viewedUserId: userId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
