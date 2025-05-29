class UserModel {
  final String name;
  final int score;

  UserModel({required this.name, required this.score});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      score: json['score'],
    );
  }
}
