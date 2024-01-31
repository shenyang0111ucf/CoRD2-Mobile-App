class UserModel {
  final String displayName;
  final String email;

  UserModel(this.displayName, this.email);

  UserModel.fromJson(Map<String, dynamic> json) :
    displayName = json['displayName'] as String,
    email = json['email'] as String;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'email': email,
  };
}