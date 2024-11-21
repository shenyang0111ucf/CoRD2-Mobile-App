import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/classes/analytics.dart';
import 'package:cord2_mobile_app/models/user_model.dart';
import 'package:cord2_mobile_app/pages/messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_model.dart';

class AddChatPage extends StatefulWidget {
  final String? userId;

  const AddChatPage({required this.userId, super.key});

  @override
  State<AddChatPage> createState() => _AddChatPageState();
}

class _AddChatPageState extends State<AddChatPage> {
  UserModel? selectedUser;
  static final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();

    _analytics.logScreenBrowsing("Add Chat");
  }

  void onSelected(UserModel selected) {
    setState(() {
      selectedUser = selected;
    });
  }

  void handleChat() {
    if (selectedUser != null) {
      // handleUserChat(selectedUser!.id!);
      Navigator.pop(context);
    }
  }

  void handleUserChat(String uid) async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref('chats/${FirebaseAuth.instance.currentUser?.uid}');
    DataSnapshot snapshot = await ref.get();
    for (DataSnapshot val in snapshot.children) {
      final map = val.value as Map?;
      List<String> participants =
          map?['participants'].map<String>((val) => val.toString()).toList();
      bool match = false;
      for (Object? part in map?['participants']) {
        Map<String, String> participant = {};
        if (part.toString() == uid) {
          match = true;
          DocumentSnapshot doc = await users.doc(part.toString()).get();
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          participant['name'] = data['name'];
          participant['uid'] = part.toString();
          DateTime lastUpdate = DateTime.parse(map!['lastUpdate'].toString());
          ChatModel chat =
              ChatModel(participant, participants, lastUpdate, val.key);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MessagePage(chat: chat)));
        }
      }
      if (match) return;
    }
    var chatId = Uuid().v4();
    DatabaseReference newChat =
        FirebaseDatabase.instance.ref('chats/${uid}/$chatId');
    var res = await newChat.update({
      "lastUpdate": DateTime.now().toString(),
      "participants": ["${uid}", "${FirebaseAuth.instance.currentUser?.uid}"]
    });
    ref = FirebaseDatabase.instance
        .ref('chats/${FirebaseAuth.instance.currentUser?.uid}/$chatId');
    res = await ref.update({
      "lastUpdate": DateTime.now().toString(),
      "participants": ["${uid}", "${FirebaseAuth.instance.currentUser?.uid}"]
    });
    DatabaseReference newMsg = FirebaseDatabase.instance.ref('msgs');
    res = await newMsg.update({chatId: []});
    Map<String, String> participant = {};
    DocumentSnapshot doc = await users.doc(uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    participant['name'] = data['name'];
    participant['uid'] = uid;
    List<String> participants = [uid, FirebaseAuth.instance.currentUser!.uid];
    DateTime lastUpdate = DateTime.now();

    ChatModel chat = ChatModel(participant, participants, lastUpdate, chatId);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => MessagePage(chat: chat)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            title: Align(
          alignment: Alignment.center,
          child: Text("Add New Chat",
              style: GoogleFonts.jost(
                  textStyle: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.normal,
                      color: Color(0xff060C3E)))),
        )),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
              color: const Color(0xffD0DCF4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _AsyncSearchAnchor(
                        currentUser: widget.userId, onSelected: onSelected),
                    Container(
                      child: Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(children: [
                            const Spacer(flex: 2),
                            Text('You have selected:',
                                style: GoogleFonts.jost(
                                    textStyle: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xff060C3E)))),
                            const Spacer(flex: 2),
                            Text(
                                '${selectedUser != null ? selectedUser!.displayName : ''}',
                                style: GoogleFonts.jost(
                                    textStyle: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xff060C3E)))),
                            const Spacer(flex: 1),
                            Text(
                                '${selectedUser != null ? selectedUser!.email : ''}',
                                style: GoogleFonts.jost(
                                    textStyle: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xff060C3E)))),
                            const Spacer(flex: 2),
                            selectedUser != null
                                ? TextButton.icon(
                                    onPressed: handleChat,
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.fromLTRB(
                                            32.0, 16.0, 32.0, 16.0),
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xff060C3E)),
                                    label: Text('Chat',
                                        style: GoogleFonts.jost(
                                            textStyle: const TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white))),
                                    icon: const Icon(Icons.chat))
                                : Container(),
                            const Spacer(flex: 4),
                          ]),
                        ),
                      ),
                    )
                  ],
                ),
              )),
        )));
  }
}

class _AsyncSearchAnchor extends StatefulWidget {
  final Function onSelected;
  final String? currentUser;

  const _AsyncSearchAnchor(
      {required this.onSelected, required this.currentUser});

  @override
  State<_AsyncSearchAnchor> createState() => _AsyncSearchAnchorState();
}

class _AsyncSearchAnchorState extends State<_AsyncSearchAnchor> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _searchingWithQuery;
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  // The most recent options received from the API.
  late Iterable<Widget> _lastOptions = <Widget>[];

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
      return SearchBar(
        controller: controller,
        padding: const MaterialStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0)),
        onTap: () {
          controller.openView();
        },
        onChanged: (_) {
          controller.openView();
        },
        leading: const Icon(Icons.search),
      );
    }, suggestionsBuilder:
            (BuildContext context, SearchController controller) async {
      List<UserModel> userList = [];
      _searchingWithQuery = controller.text;

      late final results;

      if (_searchingWithQuery != '') {
        results = await _users.orderBy('name').startAt(
            [_searchingWithQuery]).endAt(['$_searchingWithQuery\uf8ff']).get();
      } else {
        results = await _users
            .orderBy('name')
            .startAt([_searchingWithQuery])
            .endAt(['$_searchingWithQuery\uf8ff'])
            .limit(20)
            .get();
      }

      for (var doc in results.docs) {
        var userData = doc.data() as Map<String, dynamic>;

        if (doc.id != null && doc.id != widget.currentUser) {
          userList.add(UserModel.fromFirestore(userData, doc.id));
        }
      }

      final List<UserModel> options = userList;

      // If another search happened after this one, throw away these options.
      // Use the previous options instead and wait for the newer request to
      // finish.
      if (_searchingWithQuery != controller.text) {
        return _lastOptions;
      }

      _lastOptions = List<ListTile>.generate(options.length, (int index) {
        final String displayName = options[index].displayName;
        return ListTile(
          title: Text(displayName),
          onTap: () {
            widget.onSelected(options[index]);
            setState(() {
              controller.closeView('');
            });
          },
        );
      });

      return _lastOptions;
    });
  }
}
