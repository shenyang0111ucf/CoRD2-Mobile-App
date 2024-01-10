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

    print(allData);

    // loop through allData and add markers there
    for (var point in allData) {
      print('latitude');
      print(point['latitude']);
      print('longitude');
      print(point['longitude']);

      // if active show/add, otherwise dont show
      markers.add(Marker(
          point: LatLng(point['latitude'] as double, point['longitude'] as double),
          width: 56,
          height: 56,
          child: customMarker(point['latitude']as double, point['longitude'] as double)
      ));
    }



  setState(() {
    _markers = markers;
  });


  }

  MouseRegion customMarker(lat, lon) {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () => _showInfoScreen(context, lat, lon),
            child: const Icon(Icons.person_pin_circle_rounded)
        )
    );
  }

  void _showInfoScreen(context, lat, lon) {
    showModalBottomSheet(useRootNavigator: true, context: context, builder: (BuildContext bc) {
      return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 1,
          child: Column(
            children: [
              CloseButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              Center(
                  child: Text("Marker ($lat, $lon)")
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