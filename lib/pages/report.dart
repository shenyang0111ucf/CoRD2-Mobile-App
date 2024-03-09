import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
//import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

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
  String imageUrl = '';
  List<String> imageUrls = [];
  Reference referenceDirImages = FirebaseStorage.instance.ref().child('images');
  XFile? _imageFile;
  final cameraPermission = Permission.camera;
  final locationPermission = Permission.location;
  String? permType;
  late MapController mapController;

  @override
  void initState() {
    mapController = MapController();
    super.initState();
    print(currentUserId);
  }

  TextEditingController descriptionCon = TextEditingController();
  TextEditingController titleCon = TextEditingController();
  String selectedCategory = 'Hurricane';
  String _error = "";
  var chooseLat = 0.0;
  var chooseLng = 0.0;

  // takes in type of permission need/want
  // returns true/false if have/need perm
  Future<bool> checkPerms(String permType) async {
    if (permType == null) {
      print('forgot to specify perm type wanted ie.) camera, location, etc');
      return false;
    }
    if (permType == 'camera') {
      // logic for camera permission here
      final status = await Permission.camera.request();

      if (status.isGranted) {
        return true;
      }
    }
    if (permType == 'location') {
      final status = await locationPermission.request();

      if (status.isGranted) {
        return true;
      }
    }

    return false;
  }

  Future<void> pickImage() async {
    ImagePicker picker = ImagePicker();
    bool permResult = await checkPerms('camera');
    XFile? file;

    if (permResult == true) {
      file = await picker.pickImage(
          source: ImageSource.camera,
          maxHeight: 640,
          maxWidth: 640,
          imageQuality: 50,
      );
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Camera Access Denied'),
            content: const Text('Please enable camera access so that we can'
                'use your camera to take a picture of a hazard to submit. '
                'You can change this later in app settings'),
            actions: <Widget> [
              TextButton(
                  onPressed: () {
                    file = null;
                    Navigator.pop(context, 'Cancel');
                  },
                  child: const Text('Cancel')
              ),
              TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context, 'Ok');
                  },
                  child: const Text('Ok')
              ),
            ],
          )
      );
    }

    //XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file == null) {
      return;
    } else {
      setState(() {
        _imageFile = file;
      });
    }

  }

  Future<void> pickLocation() async {
    bool permResult = await checkPerms('location');
    var currentLat = 0.0;
    var currentLong = 0.0;
    if (permResult == true) {
      final position = await Geolocator.getCurrentPosition();
      currentLat = position.latitude;
      currentLong = position.longitude;
      showModalBottomSheet(
          context: context,
          builder: (context) => chooseLocationModal(context, currentLat, currentLong)
      );
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Location Access Denied'),
            content: const Text('Please enable location access so we can'
                'get your current location. Otherwise you will need to find'
                'the location on the map from a generic location. You can '
                'change this later in app settings.'),
            actions: <Widget> [
              TextButton(
                  onPressed: () {
                    //currentLat = 28.544331;
                    //currentLong = -81.191931;
                    showModalBottomSheet(
                        context: context,
                        builder: (context) => chooseLocationModal(
                            context, 28.544331, -81.191931
                        )
                    );
                    Navigator.pop(context, 'Cancel');
                  },
                  child: const Text('Cancel')
              ),
              TextButton(
                  onPressed: () {
                    openAppSettings();
                    if (currentLat == 0.0 && currentLong == 0.0) {
                      //currentLat = 28.544331;
                      //currentLong = -81.191931;
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => chooseLocationModal(
                              context, 28.544331, -81.191931
                          )
                      );
                    }
                    Navigator.pop(context, 'Ok');
                  },
                  child: const Text('Ok')
              ),
            ],
          )
      );
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
    if(_imageFile == null){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please upload an image!")));
      return;
    }
    if(chooseLat == 0.0 && chooseLng == 0.0){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Please choose a location for the hazard!")
          )
      );
      return;
    }

    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    try {
      File imageFile = File(_imageFile!.path);
      await referenceImageToUpload.putFile(imageFile);
      imageUrl = await referenceImageToUpload.getDownloadURL();
      print('Uploaded image URL: $imageUrl');
    } catch (error) {
      print('Error: $error');
    }

    imageUrls.add(imageUrl);
    // moved to own function
    /*bool permResult = await checkPerms('location');
    var currentLat = 0.0;
    var currentLong = 0.0;
    if (permResult == true) {
      final position = await Geolocator.getCurrentPosition();
      currentLat = position.latitude;
      currentLong = position.longitude;
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Location Access Denied'),
            content: const Text('Please enable location access so we can'
                'properly record the location of the hazard. Otherwise a'
                'default location will be used, and this could adversely'
                'affect individuals and first responders near the hazard. '
                'You can change this later in app settings.'),
            actions: <Widget> [
              TextButton(
                  onPressed: () {
                    currentLat = 28.544331;
                    currentLong = -81.191931;
                    Navigator.pop(context, 'Cancel');
                  },
                  child: const Text('Cancel')
              ),
              TextButton(
                  onPressed: () {
                    openAppSettings();
                    if (currentLat == 0.0 && currentLong == 0.0) {
                      currentLat = 28.544331;
                      currentLong = -81.191931;
                    }
                    Navigator.pop(context, 'Ok');
                  },
                  child: const Text('Ok')
              ),
            ],
          )
      );
    }*/

    Map<String, dynamic> submissionData = {
      'description': descriptionCon.text,
      'creator': userId,
      'images': imageUrls,
      'title': titleCon.text,
      'eventType': selectedCategory,
      'latitude': chooseLat,
      'longitude': chooseLng,
      'time': DateTime.now(),
    };

    try {
      // await _firestore.collection('users').doc(userId).update({
      //   'events': FieldValue.arrayUnion([submissionData]),
      // });
      await _firestore.collection('events').add(submissionData)
          .then((DocumentReference data) async {
        await _firestore.collection('users').doc(userId).update({
          'events': FieldValue.arrayUnion([data.id]),
        });
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
                    ElevatedButton(
                        onPressed: () {
                          pickImage();
                        },
                        child: Text('Pick Image'),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          /*showModalBottomSheet(
                              context: context,
                              builder: (context) => buildMapModal(context)
                          );*/
                          pickLocation();
                        },
                        child: const Text('Choose Location')),
                  /*  if(imageUrl.isNotEmpty){

                    }*/
                    ElevatedButton(
                      onPressed: () {
                        submitReport(currentUserId);
                      },
                      child: Text('Submit a report.'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
  }

  Widget chooseLocationModal(BuildContext context, var lat, var lng) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
              padding: EdgeInsets.all(10),
              child:  FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.close),
              )
          ),
          SizedBox(height: 5,),
          const Text(
            'Pick a location from the map',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5,),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width * 0.8,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 17.0,
                  onTap: (tapPosition, point) => {
                    print(point.toString()),
                    // create a chooseLat/lng and have setstate set them here
                    // otherwise use user's current location?
                    setState(() {
                      chooseLat = point.latitude;
                      print('CHOSEN LAT: ${chooseLat}');
                      chooseLng = point.longitude;
                      print('CHOSEN LNG: ${chooseLng}');
                      Navigator.pop(context);
                    })
                  }
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
