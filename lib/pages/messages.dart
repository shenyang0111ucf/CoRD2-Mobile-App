import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  late StreamSubscription<DatabaseEvent> _msgSubscription;
  late List<MessageModel> _messages = [];
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const SignOnPage()));
    }
    getMessages();
  }

  @override
  void dispose() {
    super.dispose();
    _msgSubscription.cancel();
  }

  void getMessages() {
    setState(() {
      _messages = [];
    });
    ChatModel chat = widget.chat;
    DatabaseReference msgRef =
        FirebaseDatabase.instance.ref('msgs/${chat.id}').orderByKey().ref;
    _msgSubscription = msgRef.onValue.listen((DatabaseEvent event) async {
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
            MessageModel(contents, sent, map!['sender'].toString(), didSend));
        setState(() {
          _messages = newList;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        });
      }
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
              tail: index == _messages.length - 1 ? true : false,
              color: item.didSend
                  ? Color(blurple)
                  : const Color(0xFFE8E8EE),
              textStyle:
                  TextStyle(color: item.didSend ? Colors.white : Colors.black));
        });
  }

  Widget renderTextScreen() {
    return Column(children: [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: renderMessages())),
      renderTextBar()
    ]);
  }

  void sendMessage() async {
    if (textController.text.isEmpty) return;
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("msgs/${widget.chat.id}/${_messages.length}");
    await ref.set({
      "sender": user?.uid,
      "contents": textController.text,
      "time": DateTime.now().toString()
    });
    DatabaseReference chatRef = FirebaseDatabase.instance.ref("chats");
    final Map<String, Map> updates = {};
    updates["${widget.chat.participants[0]}/${widget.chat.id}"] = {
      "lastUpdate": DateTime.now().toString(),
      "participants": widget.chat.participants
    };
    updates["${widget.chat.participants[1]}/${widget.chat.id}"] = {
      "lastUpdate": DateTime.now().toString(),
      "participants": widget.chat.participants
    };
    var res = await chatRef.update(updates);
    textController.clear();
  }

  Widget renderTextBar() {
    return Row(children: [
      Expanded(
        flex: 4,
        child: TextField(
          controller: textController,
          style: GoogleFonts.jost( // Applying Google Font style
            textStyle: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            )),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "..."),
        ),
      ),
      Expanded(
          child: ElevatedButton(
              onPressed: sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(blurple),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15))),
              ),
              child: Text("Send", style: GoogleFonts.jost( // Applying Google Font style
    textStyle: TextStyle(
    fontSize: 15,
    color: Colors.white,
    ),))))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _msgSubscription.cancel();
          return true;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(title: Text("${widget.chat.otherUser['name']}",   style: GoogleFonts.jost( // Applying Google Font style
    textStyle: const TextStyle(
    fontSize: 25,
    color: Colors.black,
    )))),
          body: SafeArea(
            child: Container(
              padding: EdgeInsets.only(top:20),
                color: Color(lightBlue),
                child: Center(child: renderTextScreen())),
          ),
        ));
  }
}
