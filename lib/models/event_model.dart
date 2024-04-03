import 'package:cloud_firestore/cloud_firestore.dart';

// Defines a report and allows conversion to and from JSON
class EventModel {
  final bool active;
  final String creator;
  final String description;
  final String type;
  final List images;
  final double latitude;
  final double longitude;
  final Timestamp time;
  final String title;
  final String id;

  EventModel(this.active, this.creator, this.description, this.type,
      this.images, this.latitude, this.longitude, this.time, this.title,
      [this.id = ""]);

  EventModel.fromJson(Map<String, dynamic> json)
      : active = json['active'] as bool,
        creator = json['creator'] as String,
        description = json['description'] as String,
        type = json['eventType'] as String,
        images = json['images'] as List,
        latitude = json['latitude'] as double,
        longitude = json['longitude'] as double,
        time = json['time'] as Timestamp,
        title = json['title'] as String,
        id = json['id'] != null ? json['id'] as String : "";

  Map<String, dynamic> toJson() => {
        'active': active,
        'creator': creator,
        'description': description,
        'type': type,
        'images': images,
        'latitude': latitude,
        'longitude': longitude,
        'time': time,
        'title': title
      };
}
