import 'dart:ffi';

class ChatModel {
  final Map<String, String> participant;
  final DateTime lastUpdate;
  final String? id;

  ChatModel(this.participant, this.lastUpdate, this.id);

}