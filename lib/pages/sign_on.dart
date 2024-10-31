import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class SignOnPage extends StatefulWidget {
  const SignOnPage({super.key});

  @override
  State<SignOnPage> createState() => _SignOnPageState();
}

enum Page { Login, Register, Forgot }

class _SignOnPageState extends State<SignOnPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  Page current = Page.Login;
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  String _error = "";

  final int darkBlue = 0xff5f79BA;
  final int lightBlue = 0xffD0DCF4;
  final int blurple = 0xff20297A;
  final TextStyle whiteText = const TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    // Update the stored user
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) => handleGoogleUser(account));
    // Attempt to log in a previously authorized user
    _googleSignIn.signInSilently();
  }

  void setError(String msg) {
    setState(() {
      _error = msg;
    });
  }

  // Handle the Google Authorization Flow
  void handleGoogleUser(GoogleSignInAccount? account) async {
    bool isAuthorized = account != null;
    if (isAuthorized) {
      GoogleSignInAuthentication googleAuth = await account.authentication;
      OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential firebaseCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      DocumentSnapshot doc = await users.doc(firebaseCred.user?.uid).get();
      // Found a user account
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        homePage(firebaseCred.user?.uid, data["admin"]);
      } else {
        // Need to create a new account
        users
            .doc(firebaseCred.user?.uid)
            .set({
              'name': account.displayName,
              'email': account.email,
              'events': [],
              'chats': []
            })
            .then((value) => homePage(firebaseCred.user?.uid, false))
            .catchError((err) => print("Failed to add user $err"));
      }
    }
  }

  // Wrapper to call the google auth flow
  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  // Handles the email/password registration flow
  void handleRegister() async {
    setError("");
    if (passController.text != confirmPassController.text) {
      setError("Passwords don't match");
      return;
    }
    if (passController.text.isEmpty ||
        displayNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      setError("Please fill out all fields");
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text, password: passController.text);

      users
          .doc(userCredential.user?.uid)
          .set({
            'name': displayNameController.text,
            'email': userCredential.user?.email,
            'events': [],
            'chats': []
          })
          .then((value) => print("Successfully added user!"))
          .catchError((err) => print("Failed to add user $err"));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        setError("Password is too weak");
      } else if (e.code == 'email-already-in-use') {
        setError("This email is already in use");
      }
    } catch (e) {
      print(e);
    }
  }

  // Handles the email/password authentication flow
  void handleLogin() async {
    setError("");
    if (emailController.text.isEmpty || passController.text.isEmpty) {
      setError("Please fill out all fields");
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passController.text);

      DocumentSnapshot doc = await users.doc(credential.user?.uid).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      homePage(credential.user?.uid, data["admin"]);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setError("No user found for that email");
      } else if (e.code == 'wrong-password') {
        setError("Incorrect email/password");
      } else {
        setError("Unknown error occurred");
      }
    }
  }

  void homePage(String? userId, bool? admin) {
    if (admin == true) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(userId: userId, admin: admin!)),
          (Route route) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
          (Route route) => false);
    }
  }

  FractionallySizedBox createButton(String text, onPressed) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.jost(
                textStyle: TextStyle(
              fontSize: 15,
              color: Color(blurple),
            )),
            backgroundColor: Color(blurple),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
          ),
          child: Text(text, style: whiteText)),
    );
  }

  // Handles switching between the different pages
  void switchPage(Page newPage) {
    emailController.clear();
    displayNameController.clear();
    passController.clear();
    confirmPassController.clear();
    setState(() {
      current = newPage;
      _error = "";
    });
  }

  // Sends a password reset email for a Firebase user
  void handlePassReset() async {
    if (emailController.text.isEmpty) {
      setError("Please enter an email");
      return;
    }

    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text);

    // Redirect to Login page after sending the reset
    switchPage(Page.Login);
  }

  List<Widget> registerPage() {
    return [
      Container(
          margin: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text("Create Account",
              style: GoogleFonts.jost(
                  textStyle: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.normal,
                color: Color(0xff060C3E),
              )))),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: emailController,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 15),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            hintText: "Email",
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: displayNameController,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 15),
          ),
          decoration: InputDecoration(
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Display Name"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 15),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: confirmPassController,
          obscureText: true,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 15),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Confirm Password",
          ),
        ),
      ),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: createButton("Register", () => handleRegister())),
      Text(_error, style: const TextStyle(color: Colors.red)),
      Text(
        "Already have an account?",
        style: GoogleFonts.jost(
          textStyle:
              TextStyle(color: Color(blurple), height: 1.0, fontSize: 15),
        ),
      ),
      SizedBox(height: 5),
      GestureDetector(
          child: Text("Login",
              style: GoogleFonts.jost(
                  textStyle: TextStyle(
                decoration: TextDecoration.underline,
                color: Color(blurple),
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ))),
          onTap: () {
            switchPage(Page.Login);
          }),
    ];
  }

  List<Widget> forgotPassPage() {
    return [
      Container(
          margin: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text("Forgot Password?",
              style: GoogleFonts.jost(
                  textStyle:
                      TextStyle(color: Color(blurple), fontSize: 25.0)))),
      Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: TextField(
          controller: emailController,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 15),
          ),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Enter Your Email"),
        ),
      ),
      Text(_error,
          style: GoogleFonts.jost(textStyle: TextStyle(color: Colors.red))),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: createButton("Send Reset Email", () => handlePassReset())),
      GestureDetector(
          child: Text("Login",
              style: GoogleFonts.jost(
                  textStyle: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color(blurple),
                      fontSize: 18,
                      fontStyle: FontStyle.italic))),
          onTap: () {
            switchPage(Page.Login);
          }),
    ];
  }

  List<Widget> loginPage() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text("Login",
            style: GoogleFonts.jost(
                textStyle: TextStyle(color: Color(blurple), fontSize: 30.0))),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: emailController,
          style: GoogleFonts.jost(
            textStyle:
                TextStyle(color: Colors.white, height: 1.0, fontSize: 18),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            hintText: "Email",
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: GoogleFonts.jost(
              textStyle:
                  TextStyle(color: Colors.white, height: 1.0, fontSize: 18)),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
            suffixIcon: Icon(
              Icons.lock,
              color: Colors.white,
            ),
          ),
        ),
      ),
      SizedBox(height: 5),
      GestureDetector(
          child: Text("Forgot Password?",
              style: GoogleFonts.jost(
                  textStyle: TextStyle(
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                      color: Color(blurple),
                      fontStyle: FontStyle.italic))),
          onTap: () {
            switchPage(Page.Forgot);
          }),
      Text(_error, style: const TextStyle(color: Colors.red)),
      Container(
        margin: const EdgeInsets.only(top: 0, bottom: 10),
        child: createButton("Login", () => handleLogin()),
      ),
      GestureDetector(
          child: Text("Create a New Account",
              style: GoogleFonts.jost(
                  textStyle: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color(blurple),
                      fontSize: 15,
                      fontStyle: FontStyle.italic))),
          onTap: () {
            switchPage(Page.Register);
          }),
      const SizedBox(height: 10),
      Container(
        child: SignInButton(Buttons.Google, onPressed: signInWithGoogle),
      )
    ];
  }

  List<Widget> renderCurrentPage() {
    switch (current) {
      case Page.Login:
        return loginPage();
      case Page.Register:
        return registerPage();
      case Page.Forgot:
        return forgotPassPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: Color(0xff242C73),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.fromLTRB(40, 75, 40, 75),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: renderCurrentPage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
