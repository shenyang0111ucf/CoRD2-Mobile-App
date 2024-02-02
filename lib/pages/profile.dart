import 'dart:async';

import 'package:animations/animations.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:cord2_mobile_app/classes/user_report_table.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../classes/user_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final UserData _userData = UserData();
  late DataTableSource reports;
  Color primary = const Color(0xff5f79BA);
  Color secondary = const Color(0xffD0DCF4);
  Color highlight = const Color(0xff20297A);

  _ProfilePage() {
    reports = UserReportsTable(_userData);
  }

  @override
  Widget build(BuildContext context) {
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
                          displayReports(),
                          displayUserID(),
                          displayResetPasswordButton(),
                          displayChangeEmailButton(context),
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

  Padding displayChangeEmailButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpenContainer(
        closedElevation: 0,
        closedColor: Colors.transparent,
        closedBuilder: (context, action) => ElevatedButton(
          onPressed: null,
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
        openBuilder: (context, action) {
          return updateUserEmailForm();
        },
      ),
    );
  }

  Padding displayResetPasswordButton() {
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
  Widget displayReports() {
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
          print(userTable.events);
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
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SignOnPage(),
        ),
        (route) => false);
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
    TextEditingController emailController = TextEditingController();

    return Container(
      color: secondary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                "Change Email",
                style: TextStyle(
                    color: highlight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white, height: 1.0),
                decoration: InputDecoration(
                    isDense: true,
                    hintStyle: const TextStyle(color: Colors.white),
                    fillColor: primary,
                    filled: true,
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    hintText: "New Email"),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateColor.resolveWith((states) => highlight)),
                onPressed: () {
                  if (emailController.text.isEmpty) return;

                  showDialog(
                    context: context,
                    useSafeArea: true,
                    builder: (context) {
                      // Attempt to update email
                      return FutureBuilder(
                        future: updateUserEmail(emailController.text),
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
                              print(snapshot.data);
                              if (snapshot.data != null) {
                                switch (snapshot.data!.code) {
                                  case "requires-recent-login":
                                  case "user-token-expired":
                                    print("requires login");
                                    return displayEmailAlert(
                                        "Reauthentication Needed",
                                        "For security purposes, please login to verify your identity.",
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              signOutUser();
                                            },
                                            child: const Text("Ok"),
                                          )
                                        ]);
                                  case "invalid-email":
                                    print("invalid email");
                                    return displayEmailAlert("Invalid Email",
                                        "Please ensure your email is correct.");
                                  default:
                                    print(snapshot.data!.code);
                                    return displayEmailAlert("Error Occured",
                                        "Please try again later.");
                                }
                              }

                              return displayEmailAlert(
                                  "Verify New Email Address",
                                  "A verification email has been sent to ${emailController.text}.");
                          }
                        },
                      );
                    },
                  );
                },
                child: const SizedBox(
                  width: 132,
                  child: Center(
                    child: Text(
                      "Update",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<FirebaseAuthException?> updateUserEmail(String newEmail) async {
    print("attempted update for ${newEmail}");
    try {
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      print(e);
      return e as FirebaseAuthException?;
    }
    print("navigating to profile");
    navigateToProfile();
    return null;
  }

  void navigateToProfile() {
    // Send a snack bar with email verification sent
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  AlertDialog displayEmailAlert(String alertTitle, String alertMsg,
      {List<Widget>? actions}) {
    if (actions == null || actions.isEmpty) {
      actions = [
        ElevatedButton(
            onPressed: () => Navigator.pop(context), child: const Text("Ok"))
      ];
    }

    return AlertDialog(
      title: Text(
        alertTitle,
        style: TextStyle(color: highlight),
      ),
      elevation: 10,
      content: SizedBox(
        width: 50,
        child: Text(
          alertMsg,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: actions,
    );
  }
}
