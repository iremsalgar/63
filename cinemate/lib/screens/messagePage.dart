import 'package:cinemate/widgets/navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class MessagePage extends StatefulWidget {
  final String recipientId;

  const MessagePage({required this.recipientId, super.key});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _messageRecipients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessageRecipients();
  }

  Future<void> _loadMessageRecipients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final sentMessagesSnapshot = await _firestore
            .collection('messages')
            .where('senderId', isEqualTo: currentUser.uid)
            .get();

        final receivedMessagesSnapshot = await _firestore
            .collection('messages')
            .where('recipientId', isEqualTo: currentUser.uid)
            .get();

        final recipients = sentMessagesSnapshot.docs
            .map((doc) => doc['recipientId'] as String)
            .toSet()
            .union(receivedMessagesSnapshot.docs
                .map((doc) => doc['senderId'] as String)
                .toSet())
            .toList();

        setState(() {
          _messageRecipients = recipients;
        });
      }
    } catch (e) {
      print('Error loading message recipients: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final messageData = {
            'text': message,
            'senderId': currentUser.uid,
            'recipientId': widget.recipientId,
            'timestamp': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('messages').add(messageData);
          _messageController.clear();
        }
      } catch (e) {
        print('Error sending message: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Stream<List<QueryDocumentSnapshot>> _getMessagesStream(
      String userId, String recipientId) {
    final sentMessagesStream = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final receivedMessagesStream = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: recipientId)
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    return Rx.combineLatest2<List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>, List<QueryDocumentSnapshot>>(
      sentMessagesStream,
      receivedMessagesStream,
      (sentMessages, receivedMessages) =>
          [...sentMessages, ...receivedMessages],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NaviBar()));
            },
          )
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black87,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black54,
                ),
                child: Text(
                  'Message Recipients',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                for (var recipientId in _messageRecipients)
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        _firestore.collection('users').doc(recipientId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading...'),
                          tileColor: Colors.black26,
                        );
                      } else if (snapshot.hasError) {
                        return const ListTile(
                          title: Text('Error'),
                          tileColor: Colors.black26,
                        );
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const ListTile(
                          title: Text('Unknown User'),
                          tileColor: Colors.black26,
                        );
                      } else {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final username = userData['username'] ?? 'Unknown User';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Text(
                              username[0],
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          title: Text(username,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255))),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  MessagePage(recipientId: recipientId),
                            ));
                          },
                        );
                      }
                    },
                  ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getMessagesStream(
                  currentUser?.uid ?? '', widget.recipientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                messages.sort((a, b) {
                  final timestampA = a['timestamp'] as Timestamp?;
                  final timestampB = b['timestamp'] as Timestamp?;

                  // Null check before comparison
                  if (timestampA == null || timestampB == null) {
                    return 0;
                  }

                  return timestampA.compareTo(timestampB);
                });
                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser =
                        message['senderId'] == currentUser?.uid;
                    return ListTile(
                      title: Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blueGrey[800]
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message['text'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      subtitle: Text(
                        isCurrentUser ? 'You' : 'Recipient',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      labelText: 'Enter message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
