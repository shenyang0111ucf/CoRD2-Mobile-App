import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class MessagePage extends StatefulWidget {
  final ChatModel chat;
  const MessagePage({super.key, required this.chat});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final ScrollController _scrollController = new ScrollController();
  final int darkBlue = 0xff5f79BA;
  final int lightBlue = 0xffD0DCF4;
  final int blurple = 0xff20297A;
  final TextStyle whiteText = const TextStyle(color: Colors.white);
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  late List<MessageModel> _messages = [];
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignOnPage()));
    }
    getMessages();
  }

  void getMessages() {
    ChatModel chat = widget.chat;
    DatabaseReference msgRef = FirebaseDatabase.instance.ref('msgs/${chat.id}').orderByKey().ref;
    msgRef.onValue.listen((DatabaseEvent event) async {
      List<MessageModel> newList = [];
      for (DataSnapshot val in event.snapshot.children) {
        final map = val.value as Map?;
        bool didSend = false;
        if (map?['sender'].toString() == user?.uid) {
          didSend = true;
        }
        DateTime sent = DateTime.parse(map!['time'].toString());
        String contents = map!['contents'].toString();
        newList.add(
            MessageModel(contents, sent, map!['sender'].toString(), didSend)
        );
        setState(() {
          _messages = newList;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut
          );
        });
      }
    });
    setState(() {
      _messages = [];
    });
  }

  ListView renderMessages() {
    return ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final item = _messages[index];

          return BubbleSpecialThree(
              text: item.contents,
              isSender: item.didSend,
              tail: true,
              color: item.didSend ? const Color(0xFF1B97F3) : const Color(0xFFE8E8EE),
              textStyle: TextStyle(
                  color: item.didSend ? Colors.white : Colors.black
              )
          );
        }
    );
  }

  Widget renderTextScreen() {
    return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: renderMessages()
            )
          ),
          renderTextBar()
        ]
    );
  }

  void sendMessage() async {
    if (textController.text.isEmpty) return;
    DatabaseReference ref = FirebaseDatabase.instance.ref("msgs/${widget.chat.id}/${_messages.length}");
    await ref.set({
      "sender": user?.uid,
      "contents": textController.text,
      "time": DateTime.now().toString()
    });
    DatabaseReference chatRef = FirebaseDatabase.instance.ref("chats/${widget.chat.id}");
    await chatRef.update({
      "lastUpdate": DateTime.now().toString()
    });
  }

  Widget renderTextBar() {
    return Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white, height: 1.0),
              decoration: InputDecoration(
                  isDense: true,
                  hintStyle: const TextStyle(color: Colors.white),
                  fillColor: Color(darkBlue),
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  hintText: "..."),
            ),
          ),
          Expanded(
              child: ElevatedButton(
                  onPressed: sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(blurple),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                  ),
                  child: Text("send", style: whiteText)
              )
          )
        ]
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          title: Text("${widget.chat.participant['name']}")
      ),
      body: SafeArea(
        child: Container(
            color: Color(lightBlue),
            child: Center(
                child: renderTextScreen()
            )
        ),
      ),
    );
  }
}
