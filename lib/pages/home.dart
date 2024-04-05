import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedPage extends StatefulWidget {
  const AnimatedPage({super.key});

  @override
  State<AnimatedPage> createState() => _AnimatedPageState();
}


class _AnimatedPageState extends State<AnimatedPage> {

  void initState() {
  super.initState();
  }

  @override
  void dispose() {
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.blue,
        body:
         Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
     Text(
        "Welcome to Cord2",
        style: GoogleFonts.jost(
        textStyle: TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
        ),
        ),
        ),
        SizedBox(height: 20.0),
        ElevatedButton(
        onPressed: () {
        // Implement Login Button functionality
        },
        child: Text("Login"),
        ),
        SizedBox(height: 10.0),
        ElevatedButton(
        onPressed: () {
        // Implement Signup Button functionality
        },
        child: Text("Signup"),
        ),
        ],
        ),
        ));

        }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }