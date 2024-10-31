import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
//import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAnnouncement extends StatefulWidget {
  final String? userId; // Add a variable to hold the additional String?

  const AddAnnouncement({super.key, required this.userId});
  //const AddAnnouncement({super.key});
  @override
  State<AddAnnouncement> createState() => _AddAnnouncementState();
}

class _AddAnnouncementState extends State<AddAnnouncement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get currentUserId => widget.userId ?? "";
  String error = "";

  @override
  void initState() {
    super.initState();
  }

  TextEditingController message = TextEditingController();
  TextEditingController titleCon = TextEditingController();

  void setError(String msg) {
    setState(() {
      error = msg;
    });
  }

  // Sends the announcement
  Future sendAnnouncement(String userId) async {
    setError("");
    if (titleCon.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please add a title!")));
      return;
    }

    if (message.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add a description!")));
      return;
    }

    Map<String, dynamic> announcementData = {
      'message': message.text,
      'sentBy': userId,
      'title': titleCon.text,
      'lastUpdate': DateTime.now()
    };

    try {
      await _firestore.collection('announcements').add(announcementData);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission saved successfully!")));
      message.clear();
      titleCon.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("There was an error saving the submission: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true, // Set this to true
        body: CustomScrollView(slivers: [
          // SliverAppBar with fixed "Send Announcement" text
          SliverAppBar(
            collapsedHeight: 75,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Send Announcement',
                style: GoogleFonts.jost(
                  textStyle: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff060C3E),
                  ),
                ),
                //  textAlign: TextAlign.center,
              ),
              centerTitle: true,
            ),
            // centerTitle: true,
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          // SliverList for the scrolling content
          SliverList(
            delegate: SliverChildListDelegate([
              // Padding for spacing
              const SizedBox(height: 20),

              Container(
                //    height:600,
                //   height: MediaQuery.of(context).size.height-200,
                padding: const EdgeInsets.only(top: 30, bottom: 40),
                decoration: const BoxDecoration(
                  color: Color(0xff060C3E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                //  width: double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 25, right: 25),
                          child: Text(
                            'Title',
                            style: GoogleFonts.jost(
                                textStyle: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            )),
                          )),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10,
                            left: 25,
                            right: 25), // Adjust spacing as needed
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10), // Set rounded corners
                            color: Colors
                                .white, // Set your desired background color
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10), // Adjust padding as needed
                            child: TextField(
                              controller: titleCon,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add a title',
                                hintStyle: TextStyle(
                                  fontSize: 22,
                                  color: Colors.grey,
                                ),
                              ),
                              style: GoogleFonts.jost(
                                  textStyle: const TextStyle(
                                fontSize:
                                    16, // Set your desired font size for input text
                                color: Colors
                                    .black, // Set your desired color for input text
                              )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      Padding(
                          padding: const EdgeInsets.only(left: 25, right: 25),
                          child: Text('Message',
                              style: GoogleFonts.jost(
                                  textStyle: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white)))),
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 20, top: 10, right: 20),
                          child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    10), // Set rounded corners
                                color: Colors
                                    .white, // Set your desired background color
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 10), // Adjust padding as needed
                                child: TextField(
                                  controller: message,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'Please write announcement message.',
                                    hintStyle: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  style: GoogleFonts.jost(
                                      textStyle: const TextStyle(
                                    fontSize:
                                        16, // Set your desired font size for input text
                                    color: Colors
                                        .black, // Set your desired color for input text
                                  )),
                                ),
                              ))),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            sendAnnouncement(currentUserId);
                            if (error.isNotEmpty) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                        title: Text(
                                            'Announcement Status', // Your text
                                            style: GoogleFonts.jost(
                                              // Applying Google Font style
                                              textStyle: const TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            )),
                                        // Customize underline color

                                        elevation: 10,
                                        content: SizedBox(
                                          width: 50,
                                          child: Text(error,
                                              style: GoogleFonts.jost(
                                                  textStyle: const TextStyle(
                                                fontSize:
                                                    16, // Set your desired font size for input text
                                                color: Colors
                                                    .black, // Set your desired color for input text
                                              ))),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text("Ok",
                                                  style: GoogleFonts.jost(
                                                      textStyle:
                                                          const TextStyle(
                                                    fontSize:
                                                        15, // Set your desired font size for input text
                                                    color: Colors
                                                        .black, // Set your desired color for input text
                                                  ))))
                                        ],
                                      ));
                            }
                          },
                          style: ButtonStyle(
                            minimumSize: WidgetStateProperty.all(
                                const Size(200, 50)), // Set the size here
                          ),
                          child: Text('Send Announcement',
                              style: GoogleFonts.jost(
                                  textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xff060C3E)))),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]),
          )
        ]));
  }
}
