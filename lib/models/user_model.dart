import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String displayName;
  final String email;
  String? id;

  UserModel(this.displayName, this.email);

  UserModel.fromFirestore(Map<String, dynamic> json, String uid)
      : id = uid,
        displayName = json['name'] as String,
        email = json['email'] as String;

  UserModel.fromJson(Map<String, dynamic> json)
      : displayName = json['displayName'] as String,
        email = json['email'] as String;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
      };
}
