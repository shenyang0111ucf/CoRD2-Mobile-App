import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => _Page2PageState();
}

class _Page2PageState extends State<Page2> {
  final double latitude = 28.5384;
  final double longitude = -81.3789;
  late List<Marker> _markers;
  CollectionReference events = FirebaseFirestore.instance.collection('events');
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  @override
  void initState(){
    _markers = [];
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
      print('=================================================================');
      print('Hello: ');
      print(person['name']);
      print('=================================================================');
    }

    // loop through allData and add markers there
    for (var point in allData) {
      // troubleshoot delete later
      print('=================================================================');
      print('latitude');
      print(point['latitude']);
      print('longitude');
      print(point['longitude']);
      print('active status');
      print(point['active']);
      print(point['creator']);
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

  MouseRegion customMarker(title, desc, lat, lon, eType, timeSub) {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () => _showInfoScreen(context, title, desc, lat, lon, eType, timeSub),
            child: const Icon(Icons.person_pin_circle_rounded)
        )
    );
  }

  void _showInfoScreen(context, title, desc, lat, lon, eType, timeSub) {
    showModalBottomSheet(useRootNavigator: true, context: context, builder: (BuildContext bc) {
      return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 1,
          child: Column(
            children: [
              CloseButton(
                onPressed: () => Navigator.of(context).pop(),
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
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              "$desc")
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text('[Insert Image Here]')
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Coordinates: ($lat, $lon)'),
                          const SizedBox(
                            width: 5,
                          ),
                          Text('Hazard: $eType '),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text('$timeSub')
                      ),
                    ),

                  ],
                ),
              )
            ],
          )
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    return FlutterMap(
        options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 9.0
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: "com.app.demo",
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ]
    );
  }
}