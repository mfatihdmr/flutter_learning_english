import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_request_service.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String currentUserId;
  final String viewedUserId;

  const UserProfileScreen({
    Key? key,
    required this.currentUserId,
    required this.viewedUserId,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FriendRequestService _friendRequestService = FriendRequestService();
  DocumentSnapshot? userSnapshot;
  int friendCount = 0;
  bool isAlreadyFriend = false; // Zaten arkadaş olup olmadığını kontrol etmek için

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Kullanıcı verisini getir
    userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.viewedUserId)
        .get();

    // Arkadaş sayısını almak için "friends" alt koleksiyonundan verileri çekiyoruz
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.viewedUserId)
        .collection('friends')
        .get();

    // Eğer mevcut kullanıcının id'sine sahip bir belge varsa, zaten arkadaşız demektir.
    DocumentSnapshot friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.viewedUserId)
        .collection('friends')
        .doc(widget.currentUserId)
        .get();

    setState(() {
      friendCount = friendsSnapshot.docs.length;
      isAlreadyFriend = friendDoc.exists;
    });
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _friendRequestService.sendFriendRequest(
          widget.currentUserId, widget.viewedUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaş isteği gönderildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arkadaş isteği gönderilemedi: $e')),
      );
    }
  }

  Future<void> _removeFriend() async {
    try {
      // Mevcut kullanıcının arkadaş listesinden sil
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('friends')
          .doc(widget.viewedUserId)
          .delete();

      // Görüntülenen kullanıcının arkadaş listesinden sil
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.viewedUserId)
          .collection('friends')
          .doc(widget.currentUserId)
          .delete();

      // UI'yı güncelle
      await _loadUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaşlıktan çıkarıldınız!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem sırasında hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Profili'),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.deepPurpleAccent,
      ),
      body: userSnapshot == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profil resmi
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (userSnapshot!['photoURL'] != null &&
                              userSnapshot!['photoURL'].toString().isNotEmpty)
                          ? NetworkImage(userSnapshot!['photoURL'])
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    // Kullanıcı adı
                    Text(
                      userSnapshot!['firstName'] ?? 'İsim Yok',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // E-posta
                    Text(
                      userSnapshot!['email'] ?? 'E-posta Yok',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Arkadaş sayısı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$friendCount arkadaş',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Ek bilgi: Biyografi veya Hakkında (varsa)
                    if (userSnapshot!.data().toString().contains('bio'))
                      Text(
                        userSnapshot!['bio'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 24),
                    // Butonlar: Eğer arkadaş değilse Arkadaş İsteği Gönder,
                    // eğer arkadaşsa Arkadaşlıktan Çıkar butonu göster.
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        if (!isAlreadyFriend)
                          ElevatedButton.icon(
                            onPressed: _sendFriendRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Arkadaş İsteği Gönder',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _removeFriend,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDarkMode ? Colors.blueGrey : Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.person_remove),
                            label: const Text(
                              'Arkadaşlıktan Çıkar',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  currentUserId: widget.currentUserId,
                                  receiverId: widget.viewedUserId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.blueGrey
                                : Colors.deepPurpleAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text(
                            'Sohbete Başla',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Sosyal Medya butonları (ikon şeklinde)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            // LinkedIn sayfasına yönlendirme ekleyebilirsiniz
                          },
                          icon: const Icon(Icons.link),
                          color: isDarkMode ? Colors.white : Colors.blue,
                        ),
                        IconButton(
                          onPressed: () {
                            // GitHub sayfasına yönlendirme ekleyebilirsiniz
                          },
                          icon: const Icon(Icons.code),
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ],
                    ),
                    // Diğer ek özellikler eklenebilir...
                  ],
                ),
              ),
            ),
    );
  }
}
