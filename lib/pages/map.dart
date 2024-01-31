import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter/services.dart' show rootBundle;

class DisplayMap extends StatefulWidget {
  const DisplayMap({super.key});

  @override
  State<DisplayMap> createState() => _DisplayMapPageState();
}

class _DisplayMapPageState extends State<DisplayMap> {
  final double latitude = 28.5384;
  final double longitude = -81.3789;
  late List<Marker> _markers = [];
  // related to lotis data
  late List<Marker> school_markers = [];
  late List<Marker> sunrail_markers = [];
  late List<Marker> transit_markers = [];
  late MapController mapController;
  CollectionReference events = FirebaseFirestore.instance.collection('events');
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  void refreshMap() {
    mapController.move(LatLng(28.538336, -81.379234), 17.0);
    setState(() {});
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
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.0)),
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            child: Text(map['FID'].toString(), // all have
                                style: TextStyle(
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
                            borderRadius: BorderRadius.vertical(
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
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await events.get();
    // Get data from docs and convert map to List
    final allData = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // get user
    // Get docs from collection reference
    QuerySnapshot userSnapshot = await users.get();
    // Get data from docs and convert map to List
    final allUsers = userSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();



    // loop through allData and add markers there
    for (var point in allData) {
      String theUser;
      DocumentSnapshot doc = await users.doc(point['creator'].toString()).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String username = data['name'];
      DateTime time = point['time'].toDate();

      // if active show/add, otherwise dont show
      if (point['active'] == true) {
        markers.add(Marker(
            point: LatLng(
                point['latitude'] as double, point['longitude'] as double),
            width: 56,
            height: 56,
            child: customMarker(
              point['title'],
              username,
              point['description'],
              point['latitude'] as double,
              point['longitude'] as double,
              point['eventType'],
              //time,
              DateFormat.yMEd().add_jms().format(time),
              //point['time'],
            )));
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  MouseRegion customMarker(title, user, desc, lat, lon, eType, timeSub) {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () => _showInfoScreen(
                context, title, user, desc, lat, lon, eType, timeSub),
            child: const Icon(Icons.person_pin_circle_rounded)));
  }

  // shows user submitted points
  void _showInfoScreen(context, title, user, desc, lat, lon, eType, timeSub) {
    showModalBottomSheet(
        useRootNavigator: true,
        context: context,
        builder: (BuildContext bc) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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
                    Container(
                      margin: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(25)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    '$title')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(
                                    style: const TextStyle(
                                        //fontSize: 24,
                                        //fontWeight: FontWeight.bold,
                                        ),
                                    'Submitted by: $user')),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: Text('[Insert Image Here]')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                    "$desc")),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Text('Coordinates: '),
                                    Text(
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        '($lat, $lon)'),
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    const Text('Hazard: '),
                                    Text(
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        '$eType'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Center(child: Text('$timeSub')),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          );
        });
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
    String geoJsonData = await rootBundle.loadString(paths[0]);
    String geoJsonData2 = await rootBundle.loadString(paths[1]);
    String geoJsonData3 = await rootBundle.loadString(paths[2]);

    setState(() {
      geoJsonParser.parseGeoJsonAsString(geoJsonData);
      sunrail_markers = geoJsonParser.markers;
      geoJsonParser.parseGeoJsonAsString(geoJsonData2);
      school_markers = geoJsonParser.markers;
      geoJsonParser.parseGeoJsonAsString(geoJsonData3);
      transit_markers = geoJsonParser.markers;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
            initialCenter: LatLng(latitude, longitude), initialZoom: 17.0),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshMap,
        child: const Icon(Icons.refresh),
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
