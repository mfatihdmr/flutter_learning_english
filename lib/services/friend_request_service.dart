import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Arkadaş isteği gönderme
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    await _firestore.collection('friendRequests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending', // pending, accepted, rejected
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Arkadaş isteği durumunu güncelleme (onay veya reddetme)
  Future<void> updateFriendRequestStatus(String requestId, String status) async {
    await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': status});
  }

  // Belirli bir kullanıcıya gelen arkadaş isteklerini dinleme
  Stream<QuerySnapshot> friendRequestsStream(String receiverId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}
