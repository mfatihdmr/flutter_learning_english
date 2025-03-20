import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String status;
  final String? fileUrl; // Yeni alan eklendi

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.status,
    this.fileUrl, // Nullable olarak tanımlandı
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'],
      fileUrl: map['fileUrl'], // Haritadan okuma eklendi
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'fileUrl': fileUrl, // Haritaya ekleme eklendi
    };
  }
}
