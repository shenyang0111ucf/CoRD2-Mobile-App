import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReportForm extends StatefulWidget {
  String? userId; // Add a variable to hold the additional String?

  ReportForm({required this.userId});
  //const ReportForm({super.key});
  @override
  State<ReportForm> createState() => _ReportFormState();
}


class _ReportFormState extends State<ReportForm> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get currentUserId => widget.userId ?? "";

  @override
  void initState() {
    super.initState();
    print(currentUserId);
  }

  TextEditingController descriptionCon = TextEditingController();
  TextEditingController titleCon = TextEditingController();
  String selectedCategory = 'Hurricane';
  File? _imageFile;
  String _error = "";

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void setError(String msg) {
    setState(() {
      _error = msg;
    });
  }

  // Sets the user's report vals in firebase
  Future submitReport(String userId) async {
    setError("");
    if (descriptionCon.text.isEmpty) {
      setError("Please fill out the description field.");
      return;
    }
    if (titleCon.text.isEmpty) {
      setError("Please add a title.");
      return;
    }

    Map<String, dynamic> submissionData = {
      'description': descriptionCon.text,
      'creator': userId,
      'images': [],
      'title': titleCon.text,
      'eventType': selectedCategory,
      'latitude': 28.544331,
      'longitude': -81.191931,
      'time': DateTime.now(),
    };

      try {
        await _firestore.collection('users').doc(userId).update({
          'events': FieldValue.arrayUnion([submissionData]),
        });
        print('Submission saved successfully!');
      } catch (e) {
        print('Error saving submission: $e');
      }
}

  @override
  Widget build(BuildContext context) {
    return
    Container(
      padding: const EdgeInsets.only(top: 0),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Submit a Report',
            style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 50),
          Container(
            //   height: MediaQuery.of(context).size.height-200,
            padding: const EdgeInsets.only(top: 30),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            //  width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 20, bottom: 30, right: 30, left: 30),
                      child:
                      TextField(
                        controller: titleCon,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          // Set your desired background color
                          labelText: 'Add a title.',
                        ),
                      )),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.only(right: 10, left: 10),
                      child:
                      DropdownButton<String>(
                        style: const TextStyle(
                            color: Colors.black
                        ),
                        dropdownColor: Colors.white,
                        value: selectedCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue!;
                          });
                        },
                        items: <String>[
                          'Hurricane',
                          'Earthquake',
                          'Tornado',
                          'Wildfire',
                          'Other'
                        ]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      )),
                  const SizedBox(height: 40.0),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 20, bottom: 30, right: 30, left: 30),
                      child:
                      TextField(
                        controller: descriptionCon,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          // Set your desired background color
                          labelText: 'Please provide more information.',
                        ),
                      )),
                  _imageFile == null
                      ? ElevatedButton(
                    onPressed: () {
                      pickImage();
                    },
                    child: Text('Pick Image'))
                  : Image.file(
                    _imageFile!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      submitReport(currentUserId);
                    },
                    child: Text('Submit a report.'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

