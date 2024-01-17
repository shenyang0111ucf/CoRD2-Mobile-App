import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
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
  late List<Marker> school_markers = [];
  late List<Marker> sunrail_markers = [];
  late List<Marker> transit_markers = [];
  CollectionReference events = FirebaseFirestore.instance.collection('events');
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  // instantiate parser, use the defaults
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultMarkerColor: Colors.deepOrange,
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

  // related to lotis data points
  void onTapMarkerFunction(Map<String, dynamic> map) {
    // Going to need to de switch/if-else statements here for proper popup info
    showModalBottomSheet(
        useRootNavigator: true,
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
                  Column(
                    children: [
                      Center(
                        child: Text(map['FID'].toString(),
                            style: TextStyle(fontSize: 42)),
                      ),
                      Center(
                        child: Text(map['School_Nam'].toString(),
                            style: TextStyle(fontSize: 42)),
                      ),
                      Center(
                        child: Text(map['School_Typ'].toString(),
                            style: TextStyle(fontSize: 42)),
                      ),
                    ],
                  )
                ],
              ));
        });
  }


  @override
  void initState(){
    geoJsonParser.setDefaultMarkerTapCallback(onTapMarkerFunction);
    //_markers = [];
    processData();
    createMarkers();

    super.initState();
  }

  void createMarkers() async{
    List<Marker> markers = [];
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await events.get();
    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()as Map<String, dynamic>).toList();

    // troublehoot delete later
    print(allData);

    // get user
    // Get docs from collection reference
    QuerySnapshot userSnapshot = await users.get();
    // Get data from docs and convert map to List
    final allUsers = userSnapshot.docs.map((doc) => doc.data()as Map<String, dynamic>).toList();

    // troubleshoot delete later
    print(allUsers);

    for (var person in allUsers) {
      print('----------------------------------------------------------------');
      print('Hello: ');
      print(person);
      print(person['name']);
      print(person['email']);
      print(person['events']);
      print('----------------------------------------------------------------');
    }

    // loop through allData and add markers there
    for (var point in allData) {
      String theUser;

      // troubleshoot delete later
      print('=================================================================');
      print('active status');
      print(point['active']);
      print('user');
      print(point['creator']);
      print('title');
      print(point['description']);
      print('event type');
      print(point['eventType']);
      print('coordinates');
      print('latitude');
      print(point['latitude']);
      print('longitude');
      print(point['longitude']);
      print('=================================================================');

      // if active show/add, otherwise dont show
      if (point['active'] == true) {
        //print('DANGER ZONE!');
        markers.add(Marker(
            point: LatLng(point['latitude'] as double, point['longitude'] as double),
            width: 56,
            height: 56,
            child: customMarker(
              point['title'],
              point['creator'],
              point['description'],
              point['latitude']as double,
              point['longitude'] as double,
              point['eventType'],
              point['time'],
            )
        ));
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
            onTap: () => _showInfoScreen(context, title, user, desc, lat, lon, eType, timeSub),
            child: const Icon(Icons.person_pin_circle_rounded)
        )
    );
  }

  // related to user submitted points
  void _showInfoScreen(context, title, user, desc, lat, lon, eType, timeSub) {
    showModalBottomSheet(useRootNavigator: true, context: context, builder: (BuildContext bc) {
      return Container(
        decoration:  BoxDecoration(
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
                  margin: EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.all(Radius.circular(25)),
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
                                '$title')
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text(
                                style: const TextStyle(
                                  //fontSize: 24,
                                  //fontWeight: FontWeight.bold,
                                ),
                                'Submitted by: $user')
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                            child: Text('[Insert Image Here]')
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text(
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                                "$desc")
                        ),
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
                      /*Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Center(
                            child: Text('$timeSub')
                        ),
                      ),*/

                    ],
                  ),
                )
              ],
            )
        ),
      );
    });
  }

  Future<void> processData() async {
    // parse a small test geoJson
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
  Widget build(BuildContext context) {
    return FlutterMap(
        options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 7.0
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: "com.app.demo",
          ),
          // replaced with MarkerCLusterLayerWidget
          /*MarkerLayer(
            markers: _markers,
          ),*/
          MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 50,
                size: const Size(40, 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(50),
                markers: _markers,
                builder: (context, markers) {
                  return Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                    ),
                    child: Text(
                      markers.length.toString(),
                      style:  const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      )
                    )
                  );
                }
              )),
          MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  markers: school_markers,
                  builder: (context, markers) {
                    return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green,
                        ),
                        child: Text(
                            markers.length.toString(),
                            style:  const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            )
                        )
                    );
                  }
              )),
          MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  markers: sunrail_markers,
                  builder: (context, markers) {
                    return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.yellow,
                        ),
                        child: Text(
                            markers.length.toString(),
                            style:  const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            )
                        )
                    );
                  }
              )),
          MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  markers: transit_markers,
                  builder: (context, markers) {
                    return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.red,
                        ),
                        child: Text(
                            markers.length.toString(),
                            style:  const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            )
                        )
                    );
                  }
              ))
        ]
    );
  }
}