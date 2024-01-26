import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) => handleGoogleUser(account));
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
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken
      );
      UserCredential firebaseCred = await FirebaseAuth.instance.signInWithCredential(credential);

      DocumentSnapshot doc = await users.doc(firebaseCred.user?.uid).get();
      // Found a user account
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        homePage(firebaseCred.user?.uid);
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
            .then((value) => homePage(firebaseCred.user?.uid))
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
    if (passController.text.isEmpty || displayNameController.text.isEmpty ||
        emailController.text.isEmpty || confirmPassController.text.isEmpty) {
      setError("Please fill out all fields");
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailController.text, password: passController.text
      );

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
          email: emailController.text,
          password: passController.text
      );
      homePage(credential.user?.uid);
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

  void homePage(String? userId) {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => HomePage(userId: userId)), (Route route) => false);
  }

  FractionallySizedBox createButton(String text, onPressed) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(blurple),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))
            ),
          ),
          child: Text(text, style: whiteText)
      ),
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
            style: TextStyle(color: Color(blurple), fontSize: 25.0)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Email"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: displayNameController,
          style: const TextStyle(color: Colors.white, height: 0.6),
          decoration: InputDecoration(
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Display Name"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: confirmPassController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Confirm Password",
          ),
        ),
      ),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: createButton("Register", () => handleRegister())
      ),
      Text(_error, style: const TextStyle(color: Colors.red)),
      Text("Already have an account?", style: TextStyle(color: Color(blurple))),
      GestureDetector(
          child: Text("Login",
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(blurple),
                  fontStyle: FontStyle.italic
              )
          ),
          onTap: () {
            switchPage(Page.Login);
          }),
    ];
  }

  List<Widget> forgotPassPage() {
    return [
      Container(
          margin: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text("Forgot Password?", style: TextStyle(color: Color(blurple), fontSize: 25.0))
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Enter Your Email"),
        ),
      ),
      Text(_error, style: const TextStyle(color: Colors.red)),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: createButton("Send Reset Email", () => handlePassReset())
      ),
      GestureDetector(
          child: Text("Login",
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(blurple),
                  fontStyle: FontStyle.italic
              )
          ),
          onTap: () {
            switchPage(Page.Login);
          }),
    ];
  }

  List<Widget> loginPage() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Login", style: TextStyle(color: Color(blurple), fontSize: 25.0)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Email"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
          ),
        ),
      ),
      GestureDetector(
          child: Text("Forgot Password?",
          style: TextStyle(
            decoration: TextDecoration.underline,
            color: Color(blurple),
            fontStyle: FontStyle.italic
          )
        ),
        onTap: () {
          switchPage(Page.Forgot);
        }
      ),
      Text(_error, style: const TextStyle(color: Colors.red)),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: createButton("Login", () => handleLogin()),
      ),
      GestureDetector(
          child: Text("Create a new account",
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(blurple),
                  fontStyle: FontStyle.italic
              )
          ),
          onTap: () {
            switchPage(Page.Register);
          }
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: SignInButton(Buttons.Google, onPressed: signInWithGoogle),
      ),
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
        color: Color(lightBlue),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.fromLTRB(50, 75, 50, 75),
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