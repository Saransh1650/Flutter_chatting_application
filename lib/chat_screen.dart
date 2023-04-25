import 'package:chatting_application/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

late User loggedinUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();

  final kSendButtonTextStyle = const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 18.0,
  );

  final kMessageTextFieldDecoration = const InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
    hintText: 'Type your message here...',
    border: InputBorder.none,
  );

  final kMessageContainerDecoration = const BoxDecoration(
    border: Border(
      top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    ),
  );

  final collectionStream =
      FirebaseFirestore.instance.collection('messages').snapshots();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late String messageText;
  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedinUser = user;
        print(loggedinUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void steamMessage() async {
    await for (var i in _firestore.collection('messages').snapshots()) {
      for (var j in i.docs) {
        print(j.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pushNamed(context, WelcomeScreen.id);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: const Color.fromARGB(255, 73, 198, 255),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(
                    backgroundColor: Colors.blueAccent,
                  );
                }
                if (snapshot.hasData) {
                  final messages = snapshot.data!.docs;
                  List<MessageBubble> messageWidgets = [];
                  for (var message in messages) {
                    final text = message['text'];
                    final sender = message['sender'];

                    final currentUser = loggedinUser.email;

                    MessageBubble messageWidget = MessageBubble(
                      sender: sender,
                      text: text,
                      isMe: currentUser == sender,
                    );
                    messageWidgets.add(messageWidget);
                  }
                  return Expanded(
                    child: ListView(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      children: messageWidgets,
                    ),
                  );
                } else {
                  return const Text("no data");
                }
              }),
          Container(
            decoration: kMessageContainerDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: kMessageTextFieldDecoration,
                    controller: messageController,
                    onChanged: (value) {
                      messageText = value;
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    messageController.clear();
                    _firestore.collection('messages').add({
                      'text': messageText,
                      'sender': loggedinUser.email,
                      'time': DateTime.now(),
                    });
                  },
                  child: Text(
                    'Send',
                    style: kSendButtonTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.isMe,
  });

  final String sender;
  final String text;
  bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "$sender ",
              style: TextStyle(fontSize: 12),
            ),
            Material(
                borderRadius: BorderRadius.circular(10),
                color:
                    isMe ? Color.fromARGB(255, 226, 243, 33) : Colors.black45,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 18),
                    ))),
          ]),
    );
  }
}
