import 'package:cord2_mobile_app/models/announcement_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementDetails extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetails({super.key, required this.announcement});

  @override
  State<AnnouncementDetails> createState() => _AnnouncementDetailsState();
}

class _AnnouncementDetailsState extends State<AnnouncementDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.announcement.title,
              style: GoogleFonts.jost(
                  // Applying Google Font style
                  textStyle: const TextStyle(
                fontSize: 25,
                color: Colors.black,
              )))),
      body: SafeArea(
          child: Container(
        color: const Color(0xffD0DCF4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Container(
                  decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(widget.announcement.message),
                  ))),
        ),
      )),
    );
  }
}
