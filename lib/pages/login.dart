import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignOnPage extends StatefulWidget {
  const SignOnPage({super.key});

  @override
  State<SignOnPage> createState() => _SignOnPageState();
}



class _SignOnPageState extends State<SignOnPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'email'
      ]
  );

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;

  void handleGoogleUser(GoogleSignInAccount? account) async {
    // In mobile, being authenticated means being authorized...
    bool isAuthorized = account != null;
    if (isAuthorized) {
      DocumentSnapshot doc = await users.doc(account?.id).get();
      // Found a user account
      if (doc.exists) {
        print("We found a doc");
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(data);
      } else {
        // Need to create a new account
        users
          .doc(account.id)
          .set({
            'name': account.displayName,
            'email': account.email,
            'events': [],
            'chats': []
          })
          .then((value) => print("Successfully added user!"))
          .catchError((err) => print("Failed to add user $err"));
      }
    }
    setState(() {
      _currentUser = account;
      _isAuthorized = isAuthorized;
    });
  }


  @override
  void initState() {
    super.initState();
    // Update the stored user
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) => handleGoogleUser(account));

    // Attempt to log in a previously authorized user
    _googleSignIn.signInSilently();
  }

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> signOut() => _googleSignIn.disconnect();

  @override
  Widget build(BuildContext context) {
    const TextStyle whiteText = TextStyle(color: Colors.white);
    const int darkBlue = 0xff5f79BA;
    const int lightBlue = 0xffD0DCF4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Center(
          child :const Text("CoRD2 Mobile Application")
        )
      ),
      body: Container(
        color: const Color(lightBlue),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const FractionallySizedBox(
                widthFactor: 0.8,
                child: Card(
                  color: Color(darkBlue),
                  child: Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Center(child: Text("Please Sign In", style: whiteText))
                  )
                )
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  onPressed: signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(darkBlue),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero
                    )
                  ),
                  child: const Text("Sign in with Google", style: whiteText)
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  onPressed: signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(darkBlue),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero
                    )
                  ),
                  child: const Text("Sign Out", style: whiteText)
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}