import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:cord2_mobile_app/classes/user_report_table.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../classes/user_data.dart';

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
          child: RefreshIndicator(
            onRefresh: () async {
              (reports as UserReportsTable).refreshData();
              return;
            },
            child: ListView(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 50)),
                    Text(
                      "Profile",
                      style: TextStyle(
                          color: primary, fontSize: pageHeadingfontSize),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 20)),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.elliptical(40, 40),
                            topRight: Radius.elliptical(40, 40)),
                        color: secondary,
                      ),
                      child: Column(
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
                    ),
                  ],
                ),
              ],
            ),
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

  // Displays all reports the current user has made
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
      // Retrieve user's reports
      child: FutureBuilder<List<EventModel>?>(
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
          // set the data table's report data
          userTable.events = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.none:
              return const CircularProgressIndicator();

            case ConnectionState.active:
            case ConnectionState.done:
              if (!snapshot.hasData) {
                return const Text("No reports available.");
              }
              // Display table with reports
              return PaginatedDataTable(
                source: reports,
                rowsPerPage: (reports as UserReportsTable).getMaxRowsPerPage(),
                arrowHeadColor: Colors.white,
                showFirstLastButtons: true,
                showCheckboxColumn: false,
                columnSpacing: columnSpacing,
                horizontalMargin: 25,
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

  // Displays the user's username
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
                    child: Text(FirebaseAuth.instance.currentUser?.displayName
                            .toString() ??
                        "Unavailable.")),
              ),
            )
          ]),
        ],
      ),
    );
  }

  // Signs out the current user (and should redirect them to login)
  void signOutUser() {
    FirebaseAuth.instance.signOut();
  }

  // Sends a password reset email to the current user
  Future resetUserPassword() async {
    String status;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: FirebaseAuth.instance.currentUser?.email ?? "error");
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
