import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p/screens/User/chat_screen.dart';

class InboxScreen extends StatelessWidget {
  final String currentUserId;

  InboxScreen({required this.currentUserId});

  Stream<QuerySnapshot> getChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String> getUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()!.containsKey('name')) {
      return userDoc['name'];
    } else {
      return 'Unknown User';
    }
  }

  void deleteChat(String chatId) {
    FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  void startNewChat(BuildContext context) async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: usersSnapshot.docs
              .where((doc) => doc.id != currentUserId)
              .map((userDoc) {
            final userId = userDoc.id;
            final userName = userDoc['name'];

            return ListTile(
              title: Text(userName),
              onTap: () async {
                Navigator.pop(context);

                // Check if chat already exists
                final query = await FirebaseFirestore.instance
                    .collection('chats')
                    .where('users', arrayContains: currentUserId)
                    .get();

                DocumentSnapshot? existingChat;
                for (var doc in query.docs) {
                  List users = doc['users'];
                  if (users.contains(userId)) {
                    existingChat = doc;
                    break;
                  }
                }

                String chatId;

                if (existingChat != null) {
                  chatId = existingChat.id;
                } else {
                  final newChat = await FirebaseFirestore.instance.collection('chats').add({
                    'users': [currentUserId, userId],
                    'lastMessage': '',
                    'timestamp': Timestamp.now(),
                  });
                  chatId = newChat.id;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      currentUserId: currentUserId,
                      otherUserId: userId,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient similar to HomeScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.pink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: getChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No chats yet.'));
                }

                var chats = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index];
                    var chatId = chat.id;
                    var users = List<String>.from(chat['users']);
                    var otherUserId = users.firstWhere((id) => id != currentUserId);
                    var lastMessage = chat['lastMessage'] ?? 'No messages yet';
                    var timestamp = (chat['timestamp'] as Timestamp).toDate();

                    return FutureBuilder<String>(
                      future: getUserName(otherUserId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(title: Text('Loading...'));
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  currentUserId: currentUserId,
                                  otherUserId: otherUserId,
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  child: Icon(Icons.chat, color: Colors.red),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    userSnapshot.data!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('hh:mm a').format(timestamp),
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => deleteChat(chatId),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => startNewChat(context),
        backgroundColor: Colors.red,
        child: Icon(Icons.chat),
        tooltip: 'Start New Chat',
      ),
    );
  }
}
