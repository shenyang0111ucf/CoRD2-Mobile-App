import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/pages/messages.dart';
import 'package:cord2_mobile_app/pages/search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_model.dart';
import '../models/point_data.dart';

class DisplayMap extends StatefulWidget {
  @override
  State<DisplayMap> createState() => DisplayMapPageState();
}

class DisplayMapPageState extends State<DisplayMap> {
  final double latitude = 28.5384;
  final double longitude = -81.3789;
  final permissionLocation = Permission.location;
  late List<Marker> _markers = [];
  late List<PointData> _data = [];
  // related to lotis data
  late List<Marker> school_markers = [];
  late List<Marker> sunrail_markers = [];
  late List<Marker> transit_markers = [];
  late MapController mapController;
  CollectionReference events = FirebaseFirestore.instance.collection('events');
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  String permType = '';

  // zooms closer to users current position
  void pinpointUser(lat, long) async {
    //mapController.move(LatLng(28.538336, -81.379234), 9.0);
    mapController.move(LatLng(lat, long), 15.0);
    //createMarkers();
  }

  // zooms closer to selected search result
  void zoomTo(double lat, double lon) {
    mapController.move(LatLng(lat, lon), 15.0);
  }

  // reloads submitted reports from database
  void refreshMap() async {
    createMarkers();
    mapController.move(LatLng(latitude, longitude), 9.0);
  }

  // takes in type of permission need/want
  // returns true/false if have/need perm
  Future<bool> checkPerms(String permType) async {
    if (permType == 'locationPerm') {
      final status = await permissionLocation.request();

      if (status.isGranted) {
        return true;
      }
    }

    return false;
  }

  // instantiate parser, use the defaults
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultMarkerColor: Colors.yellow[800],
    defaultPolygonBorderColor: Colors.red,
    defaultPolygonFillColor: Colors.red.withOpacity(0.1),
    defaultCircleMarkerColor: Colors.red.withOpacity(0.25),
  );

  // can filter based on criteria
  bool myFilterFunction(Map<String, dynamic> properties) {
    if (properties['FID'].toString().contains('0')) {
      return false;
    } else {
      return true;
    }
  }

  // shows lotis data points
  void onTapMarkerFunction(Map<String, dynamic> map) {
    // the specific geojsons all record diff data, so popup needs to be customized
    // for what you want to display in popup, a lot are just blank
    showModalBottomSheet(
        useRootNavigator: true,
        backgroundColor: Colors.blue[300],
        context: context,
        builder: (BuildContext bc) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 1,
              child: Column(
                children: [
                  CloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20.0)),
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            child: Text(map['FID'].toString(), // all have
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            // transit/sunrail both have StrName, school has School_Nam
                            child: map['School_Nam'] != null
                                ? Text(map['School_Nam'],
                                style: TextStyle(fontSize: 12))
                                : Text(map['StrName'],
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            // transit/sunrail both have City, school has School_Dst
                            child: map['City'] != null
                                ? Text(map['City'],
                                style: TextStyle(fontSize: 12))
                                : Text(map['School_Dst'],
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20.0)),
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            // transit/sunrail have Type, school has School_Typ
                            child: map['School_Typ'] != null
                                ? Text(map['School_Typ'],
                                style: TextStyle(fontSize: 12))
                                : Text(map['Type'],
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ));
        });
  }

  // shows user submitted reports
  void createMarkers() async {
    List<Marker> markers = [];
    List<PointData> points = [];
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await events.get();
    // Get data from docs and convert map to List
    final allData = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    QuerySnapshot userSnapshot = await users.get();
    // Get data from docs and convert map to List
    final allUsers = userSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // loop through allData and add markers there
    for (var point in allData) {
      String theUser;
      DocumentSnapshot doc = await users.doc(point['creator'].toString()).get();
      if (!mounted) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String username = data['name'];
      DateTime time = point['time'].toDate();
      String imageURL = point['images'].toString();

      // if active show/add, otherwise dont show
      if (point['active'] == true) {
        var pointData = PointData(
            point['latitude'] as double,
            point['longitude'] as double,
            point['description'],
            point['title'],
            point['eventType'],
            imageURL.substring(1, imageURL.length -1),
            DateFormat.yMEd().add_jms().format(time),
            username,
            point['creator']);

        markers.add(Marker(
            point: LatLng(
                point['latitude'] as double, point['longitude'] as double),
            width: 56,
            height: 56,
            child: customMarker(pointData)));
        points.add(pointData);
      }
    }

    setState(() {
      if (!mounted) return;
      _markers = markers;
      _data = points;
    });
  }

  MouseRegion customMarker(PointData pointData) {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () => _showInfoScreen(context, pointData),
            child: const Icon(Icons.person_pin_circle_rounded)));
  }

  // shows user submitted points
  void _showInfoScreen(BuildContext context, PointData pointData) {
    showModalBottomSheet(
        useRootNavigator: true,
        context: context,
        builder: (BuildContext bc) {
          return SingleChildScrollView(child:
          Stack(
              children:[
                Container(
                  height: MediaQuery.of(context).size.height *0.8,
                  decoration: const BoxDecoration(
                    color: Color(0xff242C73),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(top:20, bottom:20),
                            child:
                            Container(
                              margin: const EdgeInsets.all(20.0),
                              height: MediaQuery.of(context).size.height *0.65,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(25)),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top:25, bottom:5),
                                    child: Center(
                                        child: Text(
                                            style: GoogleFonts.jost(
                                                textStyle: const
                                                TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.normal,
                                                  color: Color(0xff060C3E),
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: Color(0xff242C73), // Color of the underline
                                                  decorationThickness: 2.0,     // Thickness of the underline
                                                  decorationStyle: TextDecorationStyle.solid,
                                                )),
                                            pointData.title)),
                                  ),
                                  const SizedBox(height:5),
                                  Text(
                                      style: GoogleFonts.jost(
                                          textStyle: const
                                          TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xff060C3E),
                                          )),
                                      '$pointData.eventType'),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Center(
                                        child: Text(
                                            style: GoogleFonts.jost(
                                                textStyle: const
                                                TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.normal,
                                                  color: Color(0xff060C3E),
                                                )),
                                            'Submitted by: ${pointData.creator}')),
                                  ),
                                  SizedBox(height:5),
                                  Center(
                                    child:  Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Container(
                                            color: Colors.deepOrange,
                                            child: Text(
                                                style: GoogleFonts.jost(
                                                    textStyle: const
                                                    TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.normal,
                                                      color: Colors.white,
                                                    )),
                                                pointData.description))),
                                  ),
                                  SizedBox(height:10),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: Image.network(
                                          pointData.imageURL,
                                          width: 250,
                                          height: 250,
                                        )
                                    ),
                                  ),
                                  SizedBox(height:10),
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child:
                                      Column(
                                          children:[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    style: GoogleFonts.jost(
                                                        textStyle: const
                                                        TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.normal,
                                                          color: Color(0xff060C3E),
                                                        )),
                                                    'Coordinates: (${pointData.latitude}, ${pointData.longitude})'),
                                              ],
                                            ),
                                          ])
                                  ),
                                  SizedBox(height:10),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Center(child: Text(pointData.formattedDate, style: GoogleFonts.jost(
                                        textStyle: const
                                        TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                          color: Color(0xff060C3E),
                                        )),)),
                                  ),
                                  SizedBox(height:10),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child:
                                    ElevatedButton(
                                        onPressed: () {
                                          handleUserChat(pointData.creatorId);
                                        },
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                                            EdgeInsets.all(10.0), // Adjust the padding to change the size
                                          ),
                                          backgroundColor: MaterialStateProperty.all<Color>(Color(0xff242C73)), // Default color
                                          overlayColor: MaterialStateProperty.resolveWith<Color>(
                                                (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.hovered))
                                                return Colors.blueAccent.withOpacity(0.5); // Hover color
                                              return Colors.red; // No overlay color
                                            },
                                          ),
                                        ),
                                        child: Text(
                                          "Chat with this user",
                                          style: GoogleFonts.jost(
                                              textStyle: const
                                              TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white,
                                              )),
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      ]),
                ),
                Positioned(
                  top: 20, // Adjust this value as needed
                  right: 15,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    child: CloseButton(
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

              ]));
        });
  }

  void handleUserChat(String uid) async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref('chats/${FirebaseAuth.instance.currentUser?.uid}');
    DataSnapshot snapshot = await ref.get();
    for (DataSnapshot val in snapshot.children) {
      final map = val.value as Map?;
      List<String> participants =
      map?['participants'].map<String>((val) => val.toString()).toList();
      bool match = false;
      for (Object? part in map?['participants']) {
        Map<String, String> participant = {};
        if (part.toString() == uid) {
          match = true;
          DocumentSnapshot doc = await users.doc(part.toString()).get();
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          participant['name'] = data['name'];
          participant['uid'] = part.toString();
          DateTime lastUpdate = DateTime.parse(map!['lastUpdate'].toString());
          ChatModel chat =
          ChatModel(participant, participants, lastUpdate, val.key);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MessagePage(chat: chat)));
        }
      }
      if (match) return;
    }
    var chatId = Uuid().v4();
    DatabaseReference newChat =
    FirebaseDatabase.instance.ref('chats/${uid}/$chatId');
    var res = await newChat.update({
      "lastUpdate": DateTime.now().toString(),
      "participants": ["${uid}", "${FirebaseAuth.instance.currentUser?.uid}"]
    });
    ref = FirebaseDatabase.instance
        .ref('chats/${FirebaseAuth.instance.currentUser?.uid}/$chatId');
    res = await ref.update({
      "lastUpdate": DateTime.now().toString(),
      "participants": ["${uid}", "${FirebaseAuth.instance.currentUser?.uid}"]
    });
    DatabaseReference newMsg = FirebaseDatabase.instance.ref('msgs');
    res = await newMsg.update({chatId: []});
    Map<String, String> participant = {};
    DocumentSnapshot doc = await users.doc(uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    participant['name'] = data['name'];
    participant['uid'] = uid;
    List<String> participants = [uid, FirebaseAuth.instance.currentUser!.uid];
    DateTime lastUpdate = DateTime.now();

    ChatModel chat = ChatModel(participant, participants, lastUpdate, chatId);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => MessagePage(chat: chat)));
  }

  Future<void> processData() async {
    // parses geoJson
    // normally one would use http to access geojson on web and this is
    // the reason why this function is async.
    List<String> paths = [
      'assets/LOTIS_SUNRAIL.geojson',
      'assets/LOTIS_SCHOOL.geojson',
      'assets/LOTIS_TRANSIT.geojson'
    ];

    // gets geojson from assets
    // String geoJsonData = await rootBundle.loadString(paths[0]);
    String geoJsonData2 = await rootBundle.loadString(paths[1]);
    // String geoJsonData3 = await rootBundle.loadString(paths[2]);

    setState(() {
      // geoJsonParser.parseGeoJsonAsString(geoJsonData);
      // sunrail_markers = geoJsonParser.markers;
      geoJsonParser.parseGeoJsonAsString(geoJsonData2);
      school_markers = geoJsonParser.markers;
      // geoJsonParser.parseGeoJsonAsString(geoJsonData3);
      // transit_markers = geoJsonParser.markers;
    });
  }

  @override
  void initState() {
    geoJsonParser.setDefaultMarkerTapCallback(onTapMarkerFunction);
    mapController = MapController();
    processData();
    createMarkers();
    super.initState();
  }

  Widget buildMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
          initialCenter: LatLng(latitude, longitude), initialZoom: 9.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: "com.app.demo",
        ),
        // replaced with MarkerCLusterLayerWidget
        /*MarkerLayer(
            markers: _markers,
          ),*/
        _buildClusterLayer(_markers, Colors.blue),
        _buildClusterLayer(school_markers, Colors.green),
        _buildClusterLayer(sunrail_markers, Colors.yellow),
        _buildClusterLayer(transit_markers, Colors.red),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Search(
          map: buildMap(),
          data: _data,
          onSelect: _showInfoScreen,
          mapContext: context,
          zoomTo: zoomTo),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget> [
          FloatingActionButton(
            onPressed: () {
              refreshMap();
            },
            backgroundColor:  Color(0xff060C3E),
            child: Icon(Icons.refresh, color: Colors.white),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            backgroundColor:  Color(0xff060C3E),
            onPressed: () async {
              var permResult = await checkPerms('locationPerm');
              if (permResult == true) {
                final position = await Geolocator.getCurrentPosition();
                pinpointUser(position.latitude, position.longitude);
              } else {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                        title: const Text('Location Access Denied'),
                        content: const Text('Please enable Location Access, you can'
                            'change this later in app settings.'),
                        actions: <Widget> [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, 'Cancel');
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              openAppSettings();
                              Navigator.pop(context, 'OK');
                            },
                            child: const Text('OK'),
                          )
                        ]
                    )
                );
                // use default location or insist on current position?
                //pinpointUser(latitude, longitude);
              }
            },
            child: const Icon(Icons.location_searching_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // handles clustering of points
  MarkerClusterLayerWidget _buildClusterLayer(
      List<Marker> markers, Color color) {
    return MarkerClusterLayerWidget(
        options: MarkerClusterLayerOptions(
            maxClusterRadius: 75,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            markers: markers,
            builder: (context, markers) {
              return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: color,
                  ),
                  child: Text(markers.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      )));
            }));
  }
}