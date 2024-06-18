import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cord2_mobile_app/pages/post_drill_survey.dart';

class GpsTrackerPage extends StatefulWidget {
  String? userId; // Add a variable to hold the additional String?
  List<int?> presurveyOption;

  GpsTrackerPage({required this.userId, required this.presurveyOption});
  @override
  State<GpsTrackerPage> createState() => _GpsTrackerPageState();
}

class _GpsTrackerPageState extends State<GpsTrackerPage> {
  String get currentUserId => widget.userId ?? "";
  List<LatLng> _positions = [];
  List<DateTime> _timestamps = [];
  bool _isRecording = false;
  bool _stopRequested = false;
  double _speed = 0;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final int _recordingDuration = 1; // Duration in minutes

  @override
  void initState() {
    super.initState();
  }

  double calculateSpeed(lat1, lon1, lat2, lon2, ts1, ts2){
    var p = 0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    var radiusOfEarth = 6371;
    Duration difference = ts2.difference(ts1);
    int mss = difference.inMilliseconds;
    print(mss);
    if (mss == 0) return -1;
    return radiusOfEarth * 2 * asin(sqrt(a))*60*60*1000/mss;
  }

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _stopRequested = false;
      _positions = [];
      _timestamps = [];
      _speed = 0;
    });

    final end = DateTime.now().add(Duration(minutes: _recordingDuration));
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    while (DateTime.now().isBefore(end) && !_stopRequested) {
      final position = await _geolocatorPlatform.getCurrentPosition();
      setState(() {

        if(_positions.isNotEmpty){
          _speed = calculateSpeed(_positions[_positions.length-1].latitude, _positions[_positions.length-1].longitude,
              position.latitude, position.longitude, _timestamps[_timestamps.length-1], position.timestamp);
        }
        print(_speed);
        if (_speed <= 50 && _speed >= 0){
          _positions.add(LatLng(position.latitude, position.longitude));
          _timestamps.add(position.timestamp);
        }

      });
      await Future.delayed(Duration(seconds: 1)); // Record every second
    }

    setState(() {
      _isRecording = false;
    });

    Map<String, dynamic> submissionData = {
      'time': DateTime.now(),
    };

    // if (mounted){
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => PostSurveyScreen()),
    //   );
    // }
  }

  void _stopRecording() {
    setState(() {
      _stopRequested = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Evacuation Drill Tracker'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _positions.isNotEmpty ? _positions.last : LatLng(28.600597, -81.197419),
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _positions,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  child: Text(_isRecording ? 'Recording...' : 'Start Recording'),
                ),
                if (_isRecording)
                  ElevatedButton(
                    onPressed: () {
                      _stopRecording();
                    },
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('Stop Recording'),
                  ),
                if (_positions.isNotEmpty && !_isRecording)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PostSurveyScreen(userId: currentUserId, positions: _positions, presurveyOption: widget.presurveyOption)),
                      );
                    },
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.green),
                    child: Text('Submit GPS recording'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}