import 'package:flutter/material.dart';
import 'package:cord2_mobile_app/pages/evacuation_drill.dart';
import 'package:cord2_mobile_app/survey_data.dart';

class PreSurveyScreen extends StatefulWidget {
  String? userId; // Add a variable to hold the additional String?

  PreSurveyScreen({required this.userId});
  @override
  _PreSurveyScreenState createState() => _PreSurveyScreenState();
}

class _PreSurveyScreenState extends State<PreSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _question1Controller = TextEditingController();
  String get currentUserId => widget.userId ?? "";
  List<int?> selectedOption = [];

  _PreSurveyScreenState()
  {
    for(int i=0;i<SurveyData.pre_survey.length;i++)
      {
        selectedOption.add(0);
      }
  }

  void _submitSurvey() {
    if (_formKey.currentState!.validate()) {
      // Save survey data
      // Navigate to the map screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GpsTrackerPage(userId: currentUserId, presurveyOption: selectedOption)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pre-Survey')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              for(var i = 0;i<SurveyData.pre_survey.length; i++)...[Text(SurveyData.pre_survey[i]),
                for(var j = 0;j<SurveyData.pre_survey_choices[i].length; j++)
                ListTile(
                  title: Text(SurveyData.pre_survey_choices[i][j]),
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
              ElevatedButton(
                onPressed: _submitSurvey,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}