import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:learning_eng/models/message.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;

  ChatScreen({required this.currentUserId, required this.receiverId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String? receiverEmail;
  List<String> _selectedMessageIds = [];
  bool _isSelectionMode = false;
  List<Message> _messages = [];
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _fetchReceiverEmail();
    _initAudioRecorder();
    _openAudioPlayer();
  }

  Future<void> _openAudioPlayer() async {
    try {
      await _audioPlayer.openPlayer();
    } catch (e) {
      print("Audio player açılırken hata: $e");
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _initAudioRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mikrofon izni verilmedi');
    }
    try {
      await _audioRecorder.openRecorder();
    } catch (e) {
      print("Audio recorder açılırken hata: $e");
    }
  }

  Future<void> _fetchReceiverEmail() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.receiverId).get();
      setState(() {
        receiverEmail = userDoc['email'];
      });
    } catch (e) {
      print("Receiver e-postası çekilirken hata: $e");
    }
  }

  void _sendMessage({String? text, String? fileUrl}) async {
    if ((text == null || text.trim().isEmpty) &&
        (fileUrl == null || fileUrl.trim().isEmpty))
      return;

    final message = Message(
      id: '', // Firestore tarafından oluşturulacak
      senderId: widget.currentUserId,
      receiverId: widget.receiverId,
      text: text ?? '',
      timestamp: DateTime.now(),
      status: 'sent',
      fileUrl: fileUrl,
    );

    try {
      // Gönderici için mesajı ekle
      DocumentReference messageRef = await _firestore
          .collection('users2')
          .doc(widget.currentUserId)
          .collection('conversations')
          .doc(widget.receiverId)
          .collection('messages')
          .add(message.toMap());
      await messageRef.update({'id': messageRef.id});

      // Alıcı için mesajı ekle
      DocumentReference messageRefForReceiver = await _firestore
          .collection('users2')
          .doc(widget.receiverId)
          .collection('conversations')
          .doc(widget.currentUserId)
          .collection('messages')
          .add(message.toMap());
      await messageRefForReceiver.update({'id': messageRefForReceiver.id});
    } catch (e) {
      print("Mesaj gönderme hatası: $e");
    } finally {
      _messageController.clear();
    }
  }

  Future<void> _sendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploadingFile = true;
        });
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Dosya yükleme işlemi
        Reference ref = _storage.ref().child('uploads/$fileName');
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String fileUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _isUploadingFile = false;
        });

        if (fileUrl.isNotEmpty) {
          _sendMessage(fileUrl: fileUrl);
          print("Dosya başarıyla yüklendi: $fileUrl");
        } else {
          print("Dosya URL boş geldi");
        }
      } else {
        print("Dosya seçimi iptal edildi veya geçersiz dosya yolu.");
      }
    } catch (e) {
      setState(() {
        _isUploadingFile = false;
      });
      print("Dosya yükleme hatası: $e");
    }
  }

  // Güncellenmiş ses kaydı toggle fonksiyonu:
  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      // Kayıt başlat
      try {
        final directory = await getApplicationDocumentsDirectory();
        _recordedFilePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _audioRecorder.startRecorder(
          toFile: _recordedFilePath,
          codec: Codec.aacADTS,
        );
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print("Ses kaydı başlatılırken hata: $e");
      }
    } else {
      // Kayıt durdur ve gönder
      try {
        // stopRecorder metodu dönen dosya yolunu yakalayalım
        String? recordedPath = await _audioRecorder.stopRecorder();
        setState(() {
          _isRecording = false;
        });
        if (recordedPath != null && await File(recordedPath).exists()) {
          File file = File(recordedPath);
          String fileName = recordedPath.split('/').last;
          Reference ref = _storage.ref().child('audio/$fileName');
          UploadTask uploadTask = ref.putFile(file);
          TaskSnapshot snapshot = await uploadTask;
          String fileUrl = await snapshot.ref.getDownloadURL();
          if (fileUrl.isNotEmpty) {
            _sendMessage(fileUrl: fileUrl);
            print("Ses dosyası başarıyla yüklendi: $fileUrl");
          } else {
            print("Ses dosyası URL boş geldi");
          }
        } else {
          print("Kayıt dosyası bulunamadı: $recordedPath");
        }
      } catch (e) {
        print("Ses kaydı durdurma veya gönderme hatası: $e");
      }
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.startPlayer(
        fromURI: url,
        codec: Codec.aacADTS,
        whenFinished: () {
          print('Audio playback finished');
        },
      );
    } catch (e) {
      print("Ses oynatma hatası: $e");
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
      _isSelectionMode = _selectedMessageIds.isNotEmpty;
    });
  }

  bool _canDeleteForAll(List<Message> selectedMessages) {
    for (var message in selectedMessages) {
      if (message.senderId != widget.currentUserId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _deleteSelectedMessages({required bool deleteForAll}) async {
    List<String> messageIdsToDelete = List.from(_selectedMessageIds);

    for (String messageId in messageIdsToDelete) {
      try {
        // Önce, mevcut kullanıcının sohbetinden sil
        await _firestore
            .collection('users2')
            .doc(widget.currentUserId)
            .collection('conversations')
            .doc(widget.receiverId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } catch (e) {
        print("Hesaptan mesaj silme hatası: $e");
      }

      if (deleteForAll) {
        try {
          // Ardından, diğer tarafın sohbetinden de sil
          await _firestore
              .collection('users2')
              .doc(widget.receiverId)
              .collection('conversations')
              .doc(widget.currentUserId)
              .collection('messages')
              .doc(messageId)
              .delete();
        } catch (e) {
          print('Alıcıdan mesaj silme hatası: $e');
        }
      }
    }

    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _showDeleteDialog() {
    List<Message> selectedMessages = _messages
        .where((msg) => _selectedMessageIds.contains(msg.id))
        .toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Silme Seçenekleri"),
          content: const Text("Mesajları nasıl silmek istiyorsunuz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSelectedMessages(deleteForAll: false);
              },
              child: const Text("Benden Sil"),
            ),
            if (_canDeleteForAll(selectedMessages))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSelectedMessages(deleteForAll: true);
                },
                child: const Text("Herkesten Sil"),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFileWidget(Message message, bool isMe) {
    final fileUrl = message.fileUrl ?? '';
    if (fileUrl.isEmpty) return const SizedBox.shrink();

    if (fileUrl.endsWith('.aac')) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack, color: isMe ? Colors.white : Colors.black),
          IconButton(
            icon: Icon(Icons.play_arrow,
                color: isMe ? Colors.white : Colors.black),
            onPressed: () => _playAudio(fileUrl),
          ),
        ],
      );
    } else if (fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.png') ||
        fileUrl.endsWith('.gif')) {
      return Image.network(fileUrl, fit: BoxFit.cover);
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file,
              color: isMe ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "Dosya: ${fileUrl.split('/').last}",
              style:
                  TextStyle(color: isMe ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with ${receiverEmail ?? 'Loading...'}',
          style:
              TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        ),
        backgroundColor:
            isDarkTheme ? Colors.black : Colors.deepPurpleAccent,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _showDeleteDialog,
                )
              ]
            : [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkTheme
                ? [Colors.black, Colors.grey[850]!]
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users2')
                    .doc(widget.currentUserId)
                    .collection('conversations')
                    .doc(widget.receiverId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _messages = snapshot.data!.docs.map((doc) {
                    final messageData = doc.data() as Map<String, dynamic>;
                    return Message.fromMap(messageData, doc.id);
                  }).toList();

                  return ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == widget.currentUserId;
                      final isSelected =
                          _selectedMessageIds.contains(message.id);

                      return GestureDetector(
                        onLongPress: () => _toggleSelection(message.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(message.id);
                          }
                        },
                        child: Container(
                          color: isSelected
                              ? Colors.deepPurple[400]
                              : null,
                          child: ListTile(
                            title: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? const LinearGradient(
                                          colors: [
                                            Colors.blueAccent,
                                            Colors.blue,
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.shade800,
                                            Colors.grey.shade700,
                                          ],
                                        ),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: (message.fileUrl != null &&
                                        message.fileUrl!
                                            .trim()
                                            .isNotEmpty)
                                    ? _buildFileWidget(message, isMe)
                                    : Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_isUploadingFile)
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(),
              ),
            if (_isRecording)
              const Text('Recording...',
                  style: TextStyle(color: Colors.redAccent)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file,
                      color: Colors.orangeAccent),
                  onPressed: _sendFile,
                ),
                // Ses kaydı için toggleRecording kullanılıyor.
                IconButton(
                  icon: Icon(_isRecording
                      ? Icons.stop
                      : Icons.mic),
                  color: Colors.orangeAccent,
                  onPressed: _toggleRecording,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle:
                          TextStyle(color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Colors.orangeAccent),
                  onPressed: () =>
                      _sendMessage(text: _messageController.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
