import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}
/*
class ImageUploadForm extends StatefulWidget {
  @override
  _ImageUploadFormState createState() => _ImageUploadFormState();
}

class _ImageUploadFormState extends State<ImageUploadForm> {
  late File _imageFile;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }*/

class _ReportFormState extends State<ReportForm> {

   @override
  void initState() {
    super.initState();
  }
  
  TextEditingController descriptionCon = TextEditingController();
  String selectedCategory = 'Hurricane';

  @override
  Widget build(BuildContext context) {
    return Material(child:
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
                      padding: EdgeInsets.only(right:10, left:10),
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
                      padding: const EdgeInsets.only(top:20, bottom:30, right: 30, left:30),
                      child:
                      TextField(
                        controller: descriptionCon,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white, // Set your desired background color
                          labelText: 'Please provide more information.',
                        ),
                      )),
                ],
              ),
            ),
          ),
       //   const SizedBox(height: 20.0),
          // Add other form fields as needed
          // For example: text fields, submit button, etc.
          //   Expanded(child: Container()),
          // Expanded widget to take up remaining space
        ],
      ),
    ));
  }
}
