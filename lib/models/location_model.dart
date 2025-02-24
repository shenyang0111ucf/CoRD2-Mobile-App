import 'dart:core';
import 'package:intl/intl.dart';

class Location {
  final double lat;
  final double lng;
  final DateTime lastUpdate;

  Location(this.lat, this.lng, this.lastUpdate);

  Location.fromJson(Map<String, dynamic> json)
      : lat = json['latitude'] as double,
        lng = json['longitude'] as double,
        lastUpdate =
            DateTime.fromMillisecondsSinceEpoch(json['lastUpdate'] * 1000);

  Map<String, dynamic> toJson() => {
        'latitude': lat,
        'longitude': lng,
        'lastUpdate': lastUpdate.millisecondsSinceEpoch
      };
}
