import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  void setUserId(String id) {
    _analytics.setUserId(id: id);
  }

  // General Events

  void logScreenBrowsing(String screenName) {
    print("Screen View + $screenName");
    _analytics.logScreenView(
      screenName: screenName,
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void logLogin(String method) {
    print("Log in $method");
    _analytics.logLogin(loginMethod: method);
  }

  void logSignUp(String method) {
    print("Sign Up $method");
    _analytics.logSignUp(signUpMethod: method);
  }

  void logMapPointClick(String type) {
    print("Map Point Click $type");
    _analytics.logEvent(
      name: 'map_click',
      parameters: {
        'map_point_type': type,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Interaction Events

  void logLocationChecked(double latitude, double longitude) {
    print("Location Checked");
    _analytics.logEvent(
      name: 'location_checked',
      parameters: {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void logMessageSent() {
    _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void logReportSubmitted() {
    print("Report Submitted");
    _analytics.logEvent(
      name: 'report_submitted',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void logAnnouncementViewed() {
    print("Announcement View");
    _analytics.logEvent(
      name: 'announcement_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
