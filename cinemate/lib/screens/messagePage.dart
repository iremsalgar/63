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

  @override
  void initState() {
    super.initState();
    _loadMessageRecipients();
  }

  Future<void> _loadMessageRecipients() async {
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
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
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
        actions: [
          BackButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NaviBar()));
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Message Recipients',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            for (var recipientId in _messageRecipients)
              ListTile(
                title: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(recipientId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    } else if (snapshot.hasError) {
                      return const Text('Error');
                    } else if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text('Unknown User');
                    } else {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final username = userData['username'] ?? 'Unknown User';
                      return Text(username);
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MessagePage(recipientId: recipientId),
                  ));
                },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getMessagesStream(currentUser!.uid, widget.recipientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                messages.sort((a, b) {
                  return (a['timestamp'] as Timestamp)
                      .compareTo(b['timestamp'] as Timestamp);
                });
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message['text']),
                      subtitle: Text(
                        message['senderId'] == currentUser.uid
                            ? 'You'
                            : 'Recipient',
                      ),
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
                    decoration: const InputDecoration(
                      labelText: 'Enter message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
