import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Allows access of the current logged in user's data
class UserData {
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  static final CollectionReference _events =
      FirebaseFirestore.instance.collection('events');

  // Get a user's list of reports that they have made
  static Future<List<EventModel>?> getUserReports() async {
    DocumentSnapshot userDataSnapshot = await _users
        .doc(FirebaseAuth.instance.currentUser?.uid.toString())
        .get();

    if (!userDataSnapshot.exists) return null;

    Map<String, dynamic> userData =
        userDataSnapshot.data() as Map<String, dynamic>;
    List reportIDs = userData["events"];
    List<EventModel>? reports = [];

    // Find reports and store them in a list sorting by most recent
    for (String reportID in reportIDs.reversed) {
      DocumentSnapshot eventsSnapshot = await _events.doc(reportID).get();
      Map<String, dynamic> eventData =
          eventsSnapshot.data() as Map<String, dynamic>;
      eventData["id"] = reportID;
      reports.add(EventModel.fromJson(eventData));
    }

    // No reports were submitted by the current user
    if (reports.isEmpty) return null;

    return reports;
  }
}
