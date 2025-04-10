import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/classes/analytics.dart';
import 'package:cord2_mobile_app/pages/add_chat.dart';
import 'package:cord2_mobile_app/pages/messages.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AnalyticsService analytics = AnalyticsService();
  final int darkBlue = 0xff5f79BA;
  final int lightBlue = 0xffD0DCF4;
  final int blurple = 0xff20297A;
  final TextStyle whiteText = const TextStyle(color: Colors.white);
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  late StreamSubscription<DatabaseEvent> _chatSubscription;
  late List<ChatModel> _chats = [];

  @override
  void initState() {
    super.initState();
    if (user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const SignOnPage()));
    }

    analytics.logScreenBrowsing("Messages");
    getChatData();
  }

  @override
  void dispose() {
    super.dispose();
    _chatSubscription.cancel();
  }

  void getChatData() async {
    DatabaseReference chatRef =
        FirebaseDatabase.instance.ref('chats/${user?.uid}');
    _chatSubscription = chatRef.onValue.listen((DatabaseEvent event) async {
      List<ChatModel> newList = [];
      for (DataSnapshot val in event.snapshot.children) {
        final map = val.value as Map?;
        Map<String, String> otherUser = {};
        List<String> participants = [];
        for (Object? part in map?['participants']) {
          participants.add(part.toString());
          if (part.toString() != user?.uid) {
            otherUser['uid'] = part.toString();
            DocumentSnapshot doc = await users.doc(part.toString()).get();
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            otherUser['name'] = data['name'];
          }
        }
        if (otherUser.entries.isEmpty) continue;
        DateTime lastUpdate = DateTime.parse(map!['lastUpdate'].toString());
        newList.add(ChatModel(otherUser, participants, lastUpdate, val.key));
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
                            analytics.logScreenBrowsing("Chat");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MessagePage(chat: item)));
                          },
                          child: Column(
                            children: [
                              Text("Chat with: ${item.otherUser['name']!}",
                                  style: GoogleFonts.jost(
                                    // Applying Google Font style
                                    textStyle: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  )),
                              Text(
                                  DateFormat.yMEd()
                                      .add_jms()
                                      .format(item.lastUpdate),
                                  style: GoogleFonts.jost(
                                    // Applying Google Font style
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ))
                            ],
                          )))));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddChatPage(userId: user!.uid)));
          },
          backgroundColor: const Color(0xff242C73),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            title: Align(
          alignment: Alignment.center,
          child: Text("Your Chats",
              style: GoogleFonts.jost(
                  textStyle: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.normal,
                      color: Color(0xff060C3E)))),
        )),
        body: SafeArea(
          child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                color: Color(0xffD0DCF4),
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: renderChats())),
              )),
        ));
  }
}
