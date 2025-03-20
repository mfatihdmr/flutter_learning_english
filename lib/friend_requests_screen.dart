import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning_eng/main.dart'; // Global scaffoldMessengerKey burada tanımlı
import 'chat_screen.dart';

class FriendRequestsScreen extends StatefulWidget {
  final String currentUserId;
  const FriendRequestsScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Arkadaş isteğini kabul eden fonksiyon.
  /// İsteğin durumu 'accepted' olarak güncellenir ve
  /// her iki kullanıcının da "friends" alt koleksiyonuna kayıt eklenir.
  Future<void> acceptFriendRequest({
    required String requestId,
    required String senderId,
    required String senderEmail,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserId = currentUser.uid;
    final currentUserEmail = currentUser.email!;

    // İsteğin durumunu 'accepted' olarak güncelle
    await _firestore.collection('friendRequests').doc(requestId).update({'status': 'accepted'});

    // Mevcut kullanıcının arkadaş listesine ekle (karşı taraf)
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(senderId)
        .set({
      'email': senderEmail,
      'userId': senderId,
    });

    // İsteği gönderen kullanıcının arkadaş listesine ekle (benim kullanıcı)
    await _firestore
        .collection('users')
        .doc(senderId)
        .collection('friends')
        .doc(currentUserId)
        .set({
      'email': currentUserEmail,
      'userId': currentUserId,
    });
  }

  /// Arkadaş isteğini reddeden fonksiyon.
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaş İsteklerim'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black87
            : Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('friendRequests')
            .where('receiverId', isEqualTo: widget.currentUserId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(child: Text('Yeni arkadaş isteğiniz yok.'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requestId = request.id;
              // Veriyi Map olarak alıyoruz
              final data = request.data() as Map<String, dynamic>;
              final senderId = data['senderId'];
              // Eğer 'senderEmail' alanı yoksa 'Bilinmiyor' olarak ayarlıyoruz.
              final senderEmail = data.containsKey('senderEmail') ? data['senderEmail'] : 'Bilinmiyor';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text("Arkadaş İsteği: $senderEmail"),
                  subtitle: const Text("Yeni arkadaş isteği"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            await acceptFriendRequest(
                              requestId: requestId,
                              senderId: senderId,
                              senderEmail: senderEmail,
                            );
                            // Global scaffoldMessengerKey kullanarak Snackbar gösteriyoruz.
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(content: Text('Arkadaş isteği kabul edildi.')),
                            );
                          } catch (e) {
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        },
                        child: const Text('Onayla'),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await rejectFriendRequest(requestId);
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(content: Text('Arkadaş isteği reddedildi.')),
                            );
                          } catch (e) {
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        },
                        child: const Text('Reddet'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
