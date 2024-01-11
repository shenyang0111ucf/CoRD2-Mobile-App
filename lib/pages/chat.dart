import 'dart:convert';

import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/pages/messages.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final int darkBlue = 0xff5f79BA;
  final int lightBlue = 0xffD0DCF4;
  final int blurple = 0xff20297A;
  final TextStyle whiteText = const TextStyle(color: Colors.white);
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  late List<ChatModel> _chats = [];

  @override
  void initState() {
    super.initState();
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignOnPage()));
    }
    getChatData();
  }

  void getChatData() async {
    DatabaseReference chatRef = FirebaseDatabase.instance.ref('chats');
    chatRef.onValue.listen((DatabaseEvent event) async {
      List<ChatModel> newList = [];
      for (DataSnapshot val in event.snapshot.children) {
        final map = val.value as Map?;
        Map<String, String> participant = {};
        for (Object? part in map?['participants']) {
          if (part.toString() != user?.uid) {
            participant['uid'] = part.toString();
            DocumentSnapshot doc = await users.doc(part.toString()).get();
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            participant['name'] = data['name'];
          }
        }
        if (participant.entries.isEmpty) continue;
        DateTime lastUpdate = DateTime.parse(map!['lastUpdate'].toString());
        newList.add(
          ChatModel(participant, lastUpdate, val.key)
        );
        setState(() {
          _chats = newList;
        });
      }
    });
  }

  ListView renderChats() {
    return ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final item = _chats[index];
          return Container(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessagePage(chat: item)));
                  },
                  child: Column(
                    children: [
                      Text("Chat with: ${item.participant['name']!}"),
                      Text(DateFormat.yMEd().add_jms().format(item.lastUpdate))
                    ],
                  )
                )
              )
            )
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Your Chats")
      ),
      body: SafeArea(
        child: Container(
          color: Color(lightBlue),
          child: Center(
            child: renderChats()
          )
        ),
      ),
    );
  }
}
