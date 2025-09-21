import 'dart:convert';

LoginModel loginModelFromJson(String str) =>
    LoginModel.fromJson(json.decode(str));

String loginModelToJson(LoginModel data) => json.encode(data.toJson());

class LoginModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  LoginModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        accessToken: json["access_token"] ?? "",
        tokenType: json["token_type"] ?? "",
        expiresIn: json["expires_in"] ?? 0,
        user: User.fromJson(json["user"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "access_token": accessToken,
        "token_type": tokenType,
        "expires_in": expiresIn,
        "user": user.toJson(),
      };
}

class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? faceEncoding;
  final String? pickleData;
  final String? kidneyCondition;
  final int age;
  final int bmi;
  final String gender;
  final int height;
  final int weight;
  final String createdAt;
  final String updatedAt;
  final int rewardPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.faceEncoding,
    this.pickleData,
    this.kidneyCondition,
    required this.age,
    required this.bmi,
    required this.gender,
    required this.height,
    required this.weight,
    required this.createdAt,
    required this.updatedAt,
    required this.rewardPoints,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        emailVerifiedAt: json["email_verified_at"],
        faceEncoding: json["face_encoding"],
        pickleData: json["pickle_data"],
        kidneyCondition: json["kidney_condition"],
        age: json["age"] ?? 0,
        bmi: json["bmi"] ?? 0,
        gender: json["gender"] ?? "",
        height: json["height"] ?? 0,
        weight: json["weight"] ?? 0,
        createdAt: json["created_at"] ?? "",
        updatedAt: json["updated_at"] ?? "",
        rewardPoints: json["reward_points"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "email_verified_at": emailVerifiedAt,
        "face_encoding": faceEncoding,
        "pickle_data": pickleData,
        "kidney_condition": kidneyCondition,
        "age": age,
        "bmi": bmi,
        "gender": gender,
        "height": height,
        "weight": weight,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "reward_points": rewardPoints,
      };
}





// import 'dart:convert';

// LoginModel loginModelFromJson(String str) => LoginModel.fromJson(json.decode(str));

// String loginModelToJson(LoginModel data) => json.encode(data.toJson());

// class LoginModel {
//   final String accessToken;
//   final String tokenType;
//   final int expiresIn;

//   LoginModel({
//     required this.accessToken,
//     required this.tokenType,
//     required this.expiresIn,
//   });

//   factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
//         accessToken: json["access_token"] ?? "",
//         tokenType: json["token_type"] ?? "",
//         expiresIn: json["expires_in"] ?? 0,
//       );

//   Map<String, dynamic> toJson() => {
//         "access_token": accessToken,
//         "token_type": tokenType,
//         "expires_in": expiresIn,
//       };
// }
