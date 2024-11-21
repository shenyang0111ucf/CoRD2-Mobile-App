import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/classes/analytics.dart';
import 'package:cord2_mobile_app/models/announcement_model.dart';
import 'package:cord2_mobile_app/pages/add_announcement.dart';
import 'package:cord2_mobile_app/pages/announcement_details.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Announcements extends StatefulWidget {
  final bool admin;
  const Announcements({super.key, required this.admin});

  @override
  State<Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AnalyticsService analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();

    if (user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const SignOnPage()));
    }

    analytics.logScreenBrowsing("Announcement Page");
  }

  static Stream<QuerySnapshot> listenOnCollection(String collection) async* {
    var stream = FirebaseFirestore.instance.collection(collection).snapshots();
  }

  Widget renderAnnouncements() {
    return Scrollbar(
        child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('lastUpdate', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.requireData;

        return ListView.builder(
            itemCount: announcements.size,
            itemBuilder: (context, index) {
              final item = AnnouncementModel.fromJson(
                  announcements.docs[index].data() as Map<String, dynamic>);
              return Card(
                  color: Colors.white,
                  child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                          onTap: () {
                            analytics.logAnnouncementViewed();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AnnouncementDetails(
                                        announcement: item)));
                          },
                          child: Column(
                            children: [
                              Text(item.title,
                                  style: GoogleFonts.jost(
                                    // Applying Google Font style
                                    textStyle: const TextStyle(
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
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ))
                            ],
                          ))));
            });
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          title: Align(
        alignment: Alignment.center,
        child: Text("Announcements",
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
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: renderAnnouncements())),
            )),
      ),
      floatingActionButton: widget.admin
          ? FloatingActionButton(
              child: const Icon(Icons.add_alert),
              onPressed: () => {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddAnnouncement(
                                  userId: user!.uid,
                                )))
                  })
          : Container(),
    );
  }
}
