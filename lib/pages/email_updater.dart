// Returns a form that allows the user to reset their email.
// Displays the status of the sent email reset in an alert.
import 'package:cord2_mobile_app/classes/user_data.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UpdateUserEmailForm extends StatefulWidget {
  const UpdateUserEmailForm({super.key});

  @override
  State<UpdateUserEmailForm> createState() => _UpdateUserEmailFormState();
}

// Returns a form that allows the user to reset their email.
// Displays the status of the sent email reset in an alert.
class _UpdateUserEmailFormState extends State<UpdateUserEmailForm> {
  TextEditingController emailController = TextEditingController();
  Color primary = const Color(0xff5f79BA);
  Color secondary = const Color(0xffD0DCF4);
  Color highlight = const Color(0xff20297A);
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: secondary,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                FilledButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => Colors.transparent)),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
              child: Column(
                children: [
                  Text(
                    "Change Email",
                    style: GoogleFonts.jost(
                        // Applying Google Font style
                        textStyle: const TextStyle(
                      color: Color(0xff060C3E),
                      fontSize: 24,
                    )),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.jost(
                        // Applying Google Font style
                        textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    )),
                    decoration: InputDecoration(
                        isDense: true,
                        hintStyle: const TextStyle(color: Colors.white),
                        fillColor: primary,
                        filled: true,
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15))),
                        hintText: "New Email"),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => highlight)),
                    onPressed: () {
                      if (emailController.text.isEmpty) return;

                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          // Attempt to update email
                          return PopScope(
                            canPop: false,
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
                                    // handle error cases
                                    if (snapshot.data != null) {
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
                                        case "email-is-in-use":
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
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          highlight)),
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
                    child: SizedBox(
                      width: 190,
                      child: Center(
                        child: Text(
                          "Update",
                          style: GoogleFonts.jost(
                              // Applying Google Font style
                              textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          )),
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
    );
  }

  // Updates the current user's email
  Future<FirebaseAuthException?> updateUserEmail(String newEmail) async {
    // user tried updating to the same email
    if (FirebaseAuth.instance.currentUser!.email?.compareTo(newEmail) == 0) {
      print("Tried update with same email.");
      return FirebaseAuthException(code: "same-email");
    }

    // new email is already in use
    if (await UserData.newEmailAlreadyInUse(newEmail)) {
      print("Tried update with email already in use");
      return FirebaseAuthException(code: "email-is-in-use");
    }

    try {
      await FirebaseAuth.instance.currentUser!
          .verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      print("email update error: ${e.code}");
      return e;
    }

    return null;
  }

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

  // Signs out the current user and redirects them to the login
  void signOutUser() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SignOnPage(),
        ),
        (route) => false);
  }
}
