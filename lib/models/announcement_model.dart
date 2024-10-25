class AnnouncementModel {
  final String title;
  final String message;
  final DateTime lastUpdate;
  final String? sentBy;

  AnnouncementModel(this.title, this.message, this.lastUpdate, this.sentBy);

  AnnouncementModel.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        message = json['message'] as String,
        lastUpdate = json['lastUpdate'].toDate() as DateTime,
        sentBy = json['sentBy'] as String;

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'lastUpdate': lastUpdate,
        'sentBy': sentBy
      };
}
