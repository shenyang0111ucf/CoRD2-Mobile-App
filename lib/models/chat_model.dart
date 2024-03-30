import 'dart:ffi';

class ChatModel {
  final Map<String, String> otherUser;
  final List<String> participants;
  final DateTime lastUpdate;
  final String? id;

  ChatModel(this.otherUser, this.participants, this.lastUpdate, this.id);

}