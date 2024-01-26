import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final UserData _userData = UserData();
  late DataTableSource reports;

  _ProfilePage() {
    reports = UserReportsTable(_userData);
  }

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xff5f79BA);
    Color secondary = const Color(0xffD0DCF4);
    Color highlight = const Color(0xff20297A);
    double pageHeadingfontSize = 28;

    return Material(
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 50)),
              Text(
                "Profile",
                style: TextStyle(color: primary, fontSize: pageHeadingfontSize),
              ),
              const Padding(padding: EdgeInsets.only(top: 20)),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.elliptical(40, 40),
                        topRight: Radius.elliptical(40, 40)),
                    color: secondary,
                  ),
                  child: ListView(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle,
                            size: 90,
                            color: primary,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "Report Statuses",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          FutureBuilder<Widget>(
                              future: displayReports(primary),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }

                                return snapshot.data as Widget;
                              }),
                          displayUserID(),
                          //displayUserLocation(),
                          displayResetPasswordButton(primary, highlight),
                          displayChangeEmailButton(context, primary),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ElevatedButton(
                              onPressed: () => signOutUser(),
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          highlight)),
                              child: Container(
                                alignment: Alignment.center,
                                width: 200,
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding displayChangeEmailButton(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () => {
          showModalBottomSheet(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              builder: (context) {
                return updateUserEmailForm();
              })
        },
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(primary)),
        child: Container(
          alignment: Alignment.center,
          width: 150,
          child: const Text(
            "Change Email",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Padding displayResetPasswordButton(Color primary, Color highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () => showDialog(
            context: context,
            useSafeArea: true,
            builder: (context) {
              return FutureBuilder(
                future: resetUserPassword(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const AlertDialog(
                        elevation: 10,
                        content: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );

                    case ConnectionState.active:
                    case ConnectionState.done:
                      return AlertDialog(
                        title: Text(
                          "Password Reset",
                          style: TextStyle(color: highlight),
                        ),
                        elevation: 10,
                        content: SizedBox(
                          width: 50,
                          child: Text(
                            snapshot.data,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Ok"))
                        ],
                      );
                  }
                },
              );
            }),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primary),
        ),
        child: Container(
          alignment: Alignment.center,
          width: 150,
          child: const Text(
            "Change Password",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // display's the reports made by the current user
  Future<Widget> displayReports(Color primary) async {
    TextStyle columnTitle = const TextStyle(color: Colors.white, fontSize: 18);
    double columnSpacing = 20;
    UserReportsTable userTable = reports as UserReportsTable;
    userTable.setContext(context);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          space: 0,
          thickness: 0,
          indent: 0,
          endIndent: 0,
        ),
        cardTheme: CardTheme(
          color: primary,
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>?>(
        future: UserData.getUserReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Column(
              children: [
                Text("An error occured."),
                Text("Try again later..."),
              ],
            );
          }

          userTable.reports = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.none:
              return const CircularProgressIndicator();

            case ConnectionState.active:
            case ConnectionState.done:
              if (!snapshot.hasData) {
                return const Text("No reports available.");
              }
              return PaginatedDataTable(
                source: reports,
                rowsPerPage: UserReportsTable.getMaxRowsPerPage(),
                arrowHeadColor: Colors.white,
                showFirstLastButtons: true,
                showCheckboxColumn: false,
                columnSpacing: columnSpacing,
                horizontalMargin: 12,
                columns: [
                  DataColumn(
                    label: Expanded(
                      child: Center(
                        child: Text(
                          "Report Name",
                          style: columnTitle,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "",
                      style: columnTitle,
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }

  Widget displayUserID() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text(
              "User ID:",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Padding(padding: EdgeInsets.only(right: 10)),
            Container(
              alignment: Alignment.centerLeft,
              width: 225,
              height: 30,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(FirebaseAuth.instance.currentUser?.displayName ??
                        "Unavailable.")),
              ),
            )
          ]),
        ],
      ),
    );
  }

  Widget displayUserLocation() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Your Location"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 300,
            height: 300,
            child: Placeholder(),
          )
        ],
      ),
    );
  }

  void signOutUser() {
    FirebaseAuth.instance.signOut();
  }

  Future resetUserPassword() async {
    String status;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: FirebaseAuth.instance.currentUser?.email ?? "error");
      // await Future.delayed(const Duration(seconds: 1));
      status =
          "An email has been sent to: \n${FirebaseAuth.instance.currentUser?.email}";
    } catch (e) {
      print(e);
      status = "An error occured. Please try again.";
    }
    print(status);
    return status;
  }

  Widget updateUserEmailForm() {
    return const Placeholder();
  }
}

class UserReportsTable extends DataTableSource {
  late BuildContext context;
  late UserData userData;
  List<Map<String, dynamic>>? reports;

  UserReportsTable(this.userData);

  Widget setStatus(bool status) {
    Icon statusIcon;
    Color color = Colors.black;

    if (status) {
      statusIcon = Icon(
        CupertinoIcons.check_mark,
        color: color,
      );
    } else {
      statusIcon = Icon(
        CupertinoIcons.xmark,
        color: color,
      );
    }

    // switch (status) {
    //   case "active":
    //     statusIcon = Icon(
    //       CupertinoIcons.check_mark,
    //       color: color,
    //     );
    //     break;
    //   case 1:
    //     statusIcon = Icon(
    //       CupertinoIcons.xmark,
    //       color: color,
    //     );
    //     break;
    //   case 2:
    //     statusIcon = Icon(
    //       CupertinoIcons.hourglass_bottomhalf_fill,
    //       color: color,
    //     );
    //     break;
    //   default:
    //     statusIcon = Icon(
    //       CupertinoIcons.question,
    //       color: color,
    //     );
    // }

    return statusIcon;
  }

  TextStyle dataStyle = const TextStyle(color: Colors.black);
  static const int _maxRowsPerPage = 5;

  static int getMaxRowsPerPage() {
    return _maxRowsPerPage;
  }

  void setContext(BuildContext context) {
    this.context = context;
  }

  // Returns a border radius for a specified index row
  BorderRadiusGeometry? calculateRowBorderRadius(int index) {
    BorderRadiusGeometry? borderRadius;
    if (reports == null) return null;

    // There is only a single row on a page, so create a full border radius
    if (index == reports!.length - 1 && index % _maxRowsPerPage == 0) {
      borderRadius = const BorderRadius.all(Radius.circular(10));
    }
    // Starting row has a top border radius
    else if (index % _maxRowsPerPage == 0) {
      borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(10), topRight: Radius.circular(10));
    }
    // Last row has a bottom border radius
    else if (index % _maxRowsPerPage == _maxRowsPerPage - 1 ||
        index == reports!.length - 1) {
      borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
    }
    // Middle rows have no border radius
    else {
      borderRadius = const BorderRadius.all(Radius.zero);
    }

    return borderRadius;
  }

  Widget tableDataColumnBackground(int index, Widget data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: calculateRowBorderRadius(index),
      ),
      width: 60,
      child: Center(
        child: data,
      ),
    );
  }

  Decoration? tableDataColumnDecoration(int index) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: calculateRowBorderRadius(index),
    );
  }

  @override
  DataRow? getRow(int index) {
    String eventName = reports![index]['title'];
    String eventID = reports![index]['id'];
    String eventType = reports![index]['eventType'];
    bool activeStatus = reports![index]['active'];

    print(index);
    if (reports == null) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              width: 80,
              decoration: tableDataColumnDecoration(index),
              child: Center(
                child: Text("No data.", style: dataStyle),
              ),
            ),
          ),
          const DataCell(Text(""))
        ],
      );
    }

    return DataRow(cells: [
      DataCell(
        Container(
          width: 225,
          decoration: tableDataColumnDecoration(index),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // child: Text(index.toString(), style: dataStyle)),
                  child: Text(eventName, style: dataStyle)),
            ),
          ),
        ),
        onTap: () => {
          showModalBottomSheet(
              showDragHandle: true,
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      "Report ID: \n$eventID",
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                );
              })
        },
      ),
      DataCell(
        IconButton(
          onPressed: () => {
            showModalBottomSheet(
                context: context,
                showDragHandle: true,
                useSafeArea: true,
                builder: (context) {
                  return reportDeleteConfirmation(index);
                }),
          },
          icon: const Icon(
            CupertinoIcons.trash,
            color: Colors.white,
          ),
        ),
      ),
    ]);
  }

  Widget reportDeleteConfirmation(int index) {
    return Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "This report will be permanently deleted. Would you like to continue?",
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          fixedSize: MaterialStateProperty.resolveWith(
                              (states) => const Size.fromWidth(125)),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                        reports!.removeAt(index);
                        notifyListeners();
                        print("Delete");
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  const SizedBox(
                    width: 50,
                  ),
                  // change to min/max-width
                  ElevatedButton(
                      style: ButtonStyle(
                          fixedSize: MaterialStateProperty.resolveWith(
                              (states) => const Size.fromWidth(125)),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.white12)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
    // return FutureBuilder(
    //     future: deleteReport(), builder: (context, snapshot) {});
  }

  //Future<ConnectionState>
  Future deleteReport() async {
    return const Placeholder();
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  @override
  int get rowCount => reports?.length ?? 0;

  @override
  int get selectedRowCount => 0;
}

class PasswordResetForm extends StatelessWidget {
  const PasswordResetForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
    );
  }
}

class DeleteButton {
  late int indexToDelete;

  void deleteReport(List<Map<String, dynamic>> reports) {
    reports.removeAt(indexToDelete);
  }
}

class UserData {
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  static final CollectionReference _events =
      FirebaseFirestore.instance.collection('events');

  static String? getUserID(String userEmail) {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Get a user's list of reports that they have made
  static Future<List<Map<String, dynamic>>?> getUserReports() async {
    DocumentSnapshot userDataSnapshot = await _users
        .doc(FirebaseAuth.instance.currentUser?.uid.toString())
        .get();
    if (!userDataSnapshot.exists) return null;

    Map<String, dynamic> userData =
        userDataSnapshot.data() as Map<String, dynamic>;
    List reportIDs = userData["events"];

    List<Map<String, dynamic>>? reports = [];

    // Find reports and store them in a list
    for (String reportID in reportIDs) {
      DocumentSnapshot eventsSnapshot = await _events.doc(reportID).get();

      Map<String, dynamic> eventData =
          eventsSnapshot.data() as Map<String, dynamic>;
      eventData["id"] = reportID;
      reports.add(eventData);
    }

    // No reports were submitted by the current user
    if (reports.isEmpty) return null;

    return reports;
  }
}
