import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cord2_mobile_app/survey_data.dart';

class PostSurveyScreen extends StatefulWidget {
  PostSurveyScreen({super.key, required this.positions, required this.userId, required this.presurveyOption});
  String? userId; // Add a variable to hold the additional String?
  List<int?> presurveyOption;
  final List<LatLng> positions;
  @override
  _PostSurveyScreenState createState() => _PostSurveyScreenState();

}

class _PostSurveyScreenState extends State<PostSurveyScreen> {
  String get currentUserId => widget.userId ?? "";
  final _formKey = GlobalKey<FormState>();
  final _question2Controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<int?> selectedOption = [];

  _PostSurveyScreenState()
  {
    for(int i=0;i<SurveyData.pre_survey.length;i++)
    {
      selectedOption.add(0);
    }
  }

  void _submitPostSurvey() {
    if (_formKey.currentState!.validate()) {
      // Save post-survey data
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post-survey submitted successfully!')),
      );
    }
  }

  List<GeoPoint> convertLatLngListToGeoPointList(List<LatLng> latLngList) {
    return latLngList.map((latLng) => GeoPoint(latLng.latitude, latLng.longitude)).toList();
  }

  Future submitEvacuationDrillInfo(String userId) async {
    Map<String, dynamic> submissionData = {
      'pre_survey': widget.presurveyOption,
      'post_survey': selectedOption,
      'positions': convertLatLngListToGeoPointList(widget.positions),
      'time': DateTime.now()
    };

    try {
      // await _firestore.collection('users').doc(userId).update({
      //   'events': FieldValue.arrayUnion([submissionData]),
      // });
      await _firestore.collection('drill_events').add(submissionData)
          .then((DocumentReference data) async {
        await _firestore.collection('users').doc(userId).update({
          'drill_events': FieldValue.arrayUnion([data.id]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission saved successfully!")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error saving the submission: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post-Survey')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              for(var i = 0;i<SurveyData.post_survey.length; i++)...[Text(SurveyData.post_survey[i]),
                for(var j = 0;j<SurveyData.post_survey_choices[i].length; j++)
                  ListTile(
                    title: Text(SurveyData.post_survey_choices[i][j]),
                    leading: Radio<int>(
                      value: j,
                      groupValue: selectedOption[i],
                      onChanged: (value) {
                        setState(() {
                          selectedOption[i] = value;
                          print("Button value: $value");
                        });
                      },
                    ),
                  )
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => submitEvacuationDrillInfo(currentUserId),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}