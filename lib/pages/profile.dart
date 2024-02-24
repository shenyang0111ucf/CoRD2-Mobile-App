import 'dart:async';
import 'package:animations/animations.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../classes/user_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  late List<EventModel>? userReports = [];
  Color primary = const Color(0xff5f79BA);
  Color secondary = const Color(0xffD0DCF4);
  Color highlight = const Color(0xff20297A);
  bool _isLoadingMore = false;
  bool _noMoreReports = false;
  String? _lastUsedDocID;
  final int _reportLimit = 2;
  late double _reportSectionPadding;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Change style based on device orientation
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      _reportSectionPadding = 0;
    } else {
      _reportSectionPadding = 48;
    }

    return Material(
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () async {
              // userReports = await UserData.getUserReports();
              _noMoreReports = false;
              _lastUsedDocID = null;
              _isLoadingMore = false;
              await _loadReports();
              setState(() {
                /* Refresh list of user's reports */
              });
              // Ensure user authentication status is valid
              try {
                await FirebaseAuth.instance.currentUser?.reload();
                // Allow user to login and reauthenticate
              } on FirebaseAuthException catch (e) {
                if (e.code == "user-token-expired") {
                  SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Session Expired. Reauthentication needed."),
                        backgroundColor: Colors.amber));
                  });
                  signOutUser();
                }
              }
              return;
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 50)),
                  Text(
                    "Profile",
                    style: TextStyle(color: primary, fontSize: 28),
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
                      mainAxisSize: MainAxisSize.min,
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _reportSectionPadding),
                          child: displayReportList(),
                        ),
                        displayUserData(),
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoadingMore = true;
    });

    userReports =
        await UserData.getUserReportsWithLimit(_reportLimit, _lastUsedDocID);
    setState(() {
      _isLoadingMore = false;
      _lastUsedDocID = userReports?.last.id;
      if (userReports != null && userReports!.length < _reportLimit) {
        _noMoreReports = true;
      }
    });
  }

  Future<void> _loadMoreReports() async {
    // All reports have been retrieved
    if (_noMoreReports || _isLoadingMore) return;

    // Bottom of list reached, so load more reports
    print("Tried loading more reports");
    if (!_isLoadingMore) {
      print("Loading more reports");
      setState(() {
        _isLoadingMore = true;
      });
      print("last used docID $_lastUsedDocID");
      List<EventModel>? newReports =
          await UserData.getUserReportsWithLimit(_reportLimit, _lastUsedDocID);
      print(userReports);
      print("got reports");
      setState(() {
        // Add new reports to the report list
        if (newReports != null && newReports.isNotEmpty) {
          userReports?.addAll(newReports);
          _lastUsedDocID = newReports.last.id;
          // No more reports left
        } else if (newReports != null && newReports.length < _reportLimit) {
          _noMoreReports = true;
        }
        _isLoadingMore = false;
      });
    }
  }

  // Displays all of the necessary personal data to the user
  Widget displayUserData() {
    TextStyle dataNameStyle =
        TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            displayUserID(dataNameStyle),
            const SizedBox(height: 15),
            displayUserEmail(dataNameStyle),
            const SizedBox(height: 20),
          ],
        )
      ],
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

  Widget displayReportList() {
    return SizedBox(
      height: 300,
      child: Theme(
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
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                ScrollMetrics scrollMetrics = notification.metrics;
                // Load more reports when user is near the end of the list
                if (scrollMetrics.maxScrollExtent - scrollMetrics.pixels < 30) {
                  _loadMoreReports();
                }
                return true;
              },
              // Build reports to display
              child: ListView.builder(
                  itemCount: userReports?.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(child: showFullReport(index)),
                        displayReportDeleteButton(index)
                      ],
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }

  Widget displayReportDeleteButton(int index) {
    return IconButton(
      onPressed: () async => {
        await showDialog(
          context: context,
          useSafeArea: true,
          builder: (context) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              title: Text(
                "Delete Report",
                style: TextStyle(
                  color: highlight,
                ),
              ),
              elevation: 10,
              content: const SizedBox(
                width: 50,
                child: Text(
                  "This report will be permanently deleted. Would you like to continue?",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                    style: ButtonStyle(
                        fixedSize: MaterialStateProperty.resolveWith(
                            (states) => const Size.fromWidth(125)),
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => highlight)),
                    onPressed: () {
                      Navigator.pop(context);
                      deleteReport([userReports![index].id]);
                      userReports!.removeAt(index);
                      print("Delete");
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )),
                const SizedBox(
                  width: 50,
                ),
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
            );
          },
        ),
      },
      icon: const Icon(
        CupertinoIcons.trash,
        color: Colors.white,
      ),
    );
  }

  void deleteReport(List<String> reportID) async {
    print(reportID);
    bool deletedSuccessfully = await UserData.deleteUserReports(reportID);

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (!deletedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("An error occured deleting the event."),
            backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Successfully deleted"),
            backgroundColor: Colors.red));
      }
    });
  }

  // Displays the full report that was tapped on in the data table
  Widget showFullReport(int index) {
    return OpenContainer(
      closedShape:
          RoundedRectangleBorder(borderRadius: calculateRowBorderRadius(index)),
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: Colors.white,
      openElevation: 4.0,
      closedBuilder: (context, action) => Container(
        decoration: tableDataColumnDecoration(index),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(userReports![index].title, style: dataStyle)),
          ),
        ),
      ),
      openBuilder: (context, action) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Theme(
                data: ThemeData(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(),
                    Text(
                      userReports![index].title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        wordSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DataTable(
                      columnSpacing: 40,
                      dataTextStyle: dataStyle,
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: double.infinity,
                      headingRowHeight: 2,
                      columns: [
                        DataColumn(label: Container()),
                        DataColumn(label: Container()),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            const DataCell(Text("Type")),
                            DataCell(
                              Flex(
                                direction: Axis.horizontal,
                                children: [
                                  SizedBox(
                                    child: Text(userReports![index].type),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text("Description")),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(userReports![index].description),
                            ))
                          ],
                        ),
                        DataRow(cells: [
                          const DataCell(Text("Date Created")),
                          DataCell(
                            Text(
                                "${DateFormat.yMMMd().add_jmz().format(userReports![index].time.toDate())} ${userReports![index].time.toDate().timeZoneName}"),
                          )
                        ]),
                        DataRow(cells: [
                          const DataCell(Text("Active")),
                          DataCell(
                            setStatus(userReports![index].active),
                          )
                        ]),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle reportItem = const TextStyle(fontSize: 16);

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

    return statusIcon;
  }

  TextStyle dataStyle = const TextStyle(
      color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500);

  // Returns a border radius for a specified index row
  BorderRadiusGeometry calculateRowBorderRadius(int index) {
    BorderRadiusGeometry? borderRadius;
    //if (events == null) return null;

    // There is only a single row on a page, so create a full border radius
    if (userReports!.length == 1) {
      borderRadius = const BorderRadius.all(Radius.circular(10));
    }
    // Starting row has a top border radius
    else if (index == 0) {
      borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(10), topRight: Radius.circular(10));
    }
    // Last row has a bottom border radius
    else if (index == userReports!.length - 1) {
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

  // Displays the user's username
  Widget displayUserID(TextStyle dataNameStyle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "ID",
        style: dataNameStyle,
      ),
      const SizedBox(height: 8),
      //const Padding(padding: EdgeInsets.only(right: 10)),
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
              child: Text(
                  FirebaseAuth.instance.currentUser?.displayName.toString() ??
                      "Unavailable.")),
        ),
      )
    ]);
  }

  // Displays the user's email
  Widget displayUserEmail(TextStyle dataNameStyle) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Email",
            style: dataNameStyle,
          ),
          const SizedBox(height: 8),
          //const Padding(padding: EdgeInsets.only(right: 10)),
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
                child: Text(
                    FirebaseAuth.instance.currentUser?.email ?? "unavailable."),
              ),
            ),
          )
        ]);
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

  Future<void> signInWithGoogle() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
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
              const Row(
                children: [BackButton()],
              ),
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
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      // Attempt to update email
                      return WillPopScope(
                        onWillPop: () async {
                          return false;
                        },
                        child: FutureBuilder(
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
                                  // handle error cases
                                  switch (snapshot.data!.code) {
                                    case "requires-recent-login":
                                    case "user-token-expired":
                                      print("requires login");
                                      return displayAlert(
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
                                      return displayAlert("Invalid Email",
                                          "Please ensure your email is correct.");
                                    case "same-email":
                                      return displayAlert(
                                          "Cannot Update to Same Email",
                                          "You must update to a different email than your current email.");
                                    // not working
                                    case "email-already-exists":
                                    case "email-already-in-use":
                                      return displayAlert(
                                          "Email Already in Use",
                                          "This email is already taken. Please choose a different email.");
                                    default:
                                      print(snapshot.data!.code);
                                      return displayAlert("Error Occured",
                                          "Please try again later.");
                                  }
                                }

                                // Email verification sent successfully, so prepare for reauthentication.
                                return displayAlert(
                                  "Verify New Email Address",
                                  "A verification email has been sent to ${emailController.text}.",
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        signOutUser();
                                      },
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateColor.resolveWith(
                                                  (states) => highlight)),
                                      child: const Text("Ok"),
                                    ),
                                  ],
                                );
                            }
                          },
                        ),
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
              ),
              const SizedBox(height: 10),
              Text("OR",
                  style: TextStyle(
                      color: primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child:
                    SignInButton(Buttons.Google, onPressed: signInWithGoogle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<FirebaseAuthException?> updateUserEmail(String newEmail) async {
    if (FirebaseAuth.instance.currentUser!.email?.compareTo(newEmail) == 0) {
      print("Tried update with same email");
      return FirebaseAuthException(code: "same-email");
    }

    print("attempted update for ${newEmail}");
    try {
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      print("email update error: ${e.code}");
      return e;
    }

    return null;
  }

  // Returns a custom preset alert dialog
  AlertDialog displayAlert(String alertTitle, String alertMsg,
      {List<Widget>? actions}) {
    // Default "Ok" button when no actions are passed
    if (actions == null || actions.isEmpty) {
      actions = [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateColor.resolveWith((states) => highlight)),
          child: const Text("Ok"),
        )
      ];
    }

    // Custom alert dialog
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
