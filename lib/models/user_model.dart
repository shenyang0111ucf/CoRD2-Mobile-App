import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class UserModel {
  final String displayName;
  final String email;
  String? id;
  Location? location;

  UserModel(this.displayName, this.email);

  UserModel.fromFirestore(Map<String, dynamic> json, String uid)
      : id = uid,
        displayName = json['name'] as String,
        email = json['email'] as String,
        location = json.containsKey('location')
            ? Location.fromJson(json['location'])
            : null;

  UserModel.fromJson(Map<String, dynamic> json)
      : displayName = json['displayName'] as String,
        email = json['email'] as String,
        location = json.containsKey('location')
            ? Location.fromJson(json['location'])
            : null;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'location': location?.toJson()
      };
}
