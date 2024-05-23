import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Allows access of the current logged in user's data
class UserData {
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  static final CollectionReference _events =
      FirebaseFirestore.instance.collection('events');

  // Retrieves a specified limit of the
  // current user's reports sorted by most recent or oldest
  static Future<List<EventModel>?> getUserReportsWithLimit(
      int limit, String? lastUsedDocID, bool sortByRecent) async {
    QuerySnapshot? userDataSnapshot;
    // Retrieves the first limit of events
    if (lastUsedDocID == null) {
      userDataSnapshot = await _events
          .where('creator', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          // 'descending' determines whether the list retrieved is sorted
          // by most recent or oldest.
          .orderBy('time', descending: sortByRecent)
          .limit(limit)
          .get();
      // Retrieves reports from the last document retrieved
    } else {
      await _events.doc(lastUsedDocID).get().then((lastUsedDoc) async {
        userDataSnapshot = await _events
            .where('creator', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('time', descending: sortByRecent)
            .startAfterDocument(lastUsedDoc)
            .limit(limit)
            .get();
      }).onError((error, stackTrace) async {
        print(error);
      });
    }
    // No reports found
    if (userDataSnapshot?.docs == null) return null;

    List<EventModel>? reports = [];

    // Create a list of reports
    for (QueryDocumentSnapshot<Object?> doc in userDataSnapshot!.docs) {
      Map<String, dynamic> eventData = doc.data() as Map<String, dynamic>;
      // Get reports that contain the searched text
      eventData["id"] = doc.id;
      reports.add(EventModel.fromJson(eventData));
    }

    return reports;
  }

  // Get a user's list of reports that they have made
  static Future<List<EventModel>?> getUserReports() async {
    DocumentSnapshot userDataSnapshot =
        await _users.doc(FirebaseAuth.instance.currentUser?.uid).get();

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

  // Attempts to delete a list of events.
  // Returns true when delete was successful, otherwise false.
  static Future<bool> deleteUserReports(List<String> eventDocIDs) async {
    bool errorOccurred = false;
    // Delete each document with the specified ID
    for (String eventDocID in eventDocIDs) {
      await _events.doc(eventDocID).delete().catchError((e) {
        print("Error deleting document: $e");
        errorOccurred = true;
      });

      // Updates user's event list only when event deletion was successful
      if (!errorOccurred) {
        final updates = <String, dynamic>{
          'events': FieldValue.arrayRemove([eventDocID])
        };

        await _users
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update(updates);
      }
    }
    return !errorOccurred;
  }

  // Returns a string that the email sent was successful or an error occured.
  // Sends a password reset email to the current user.
  static Future resetUserPassword() async {
    String status;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: FirebaseAuth.instance.currentUser?.email ?? "error");
      status =
          "An email has been sent to: \n${FirebaseAuth.instance.currentUser?.email}";
    } catch (e) {
      print(e);
      status = "An error occured. Please try again.";
    }
    return status;
  }

  // Determines whether a user logged in by using email and password.
  static bool isEmailPassLoginType() {
    User? user = FirebaseAuth.instance.currentUser;

    // User logged in with email and password
    if (user?.providerData[0].providerId == "password") {
      return true;
    }
    // User logged in with another provider. Ex: google.com
    return false;
  }

  // Determines if an email is used by another user
  static Future<bool> newEmailAlreadyInUse(String newEmail) async {
    QuerySnapshot? userDataSnapshot;
    // Retrieves the first limit of events
    userDataSnapshot =
        await _users.where('email', isEqualTo: newEmail).limit(1).get();

    return userDataSnapshot.docs.isNotEmpty;
  }

  // Determines if an email is used by another user
  static Future<String?> getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDataSnapshot = await _users.doc(user.uid).get();

    if (!userDataSnapshot.exists) return null;

    Map<String, dynamic> userData =
        userDataSnapshot.data() as Map<String, dynamic>;

    return userData['name'];
  }
}
