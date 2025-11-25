import 'dart:convert';


import 'dart:convert';

LoginModel loginModelFromJson(String str) =>
    LoginModel.fromJson(json.decode(str) as Map<String, dynamic>);

String loginModelToJson(LoginModel data) => json.encode(data.toJson());

class LoginModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final int totalPoints;
  final User user;
  final List<Appointment> appointments;
  final List<Bmi> bmi;
  final List<Reward> rewards;
  final List<Calorie> calories;
  List<Professional> professionals;

  LoginModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.totalPoints,
    required this.user,
    required this.appointments,
    required this.bmi,
    required this.rewards,
    required this.calories,
    required this.professionals,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        accessToken: _asString(json["access_token"]) ?? "",
        tokenType: _asString(json["token_type"]) ?? "",
        expiresIn: _asInt(json["expires_in"]) ?? 0,
        totalPoints: _asInt(json["total_points"]) ?? 0,
        user: User.fromJson((json["user"] ?? {}) as Map<String, dynamic>),
        appointments: ((json["appointments"] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Appointment.fromJson(e))
            .toList(),
        bmi: ((json["bmi"] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Bmi.fromJson(e))
            .toList(),
        rewards: ((json["rewards"] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Reward.fromJson(e))
            .toList(),
        calories: ((json["calories"] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Calorie.fromJson(e))
            .toList(),
            professionals: List<Professional>.from(json["professionals"].map((x) => Professional.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "access_token": accessToken,
        "token_type": tokenType,
        "expires_in": expiresIn,
        "total_points": totalPoints,
        "user": user.toJson(),
        "appointments": appointments.map((x) => x.toJson()).toList(),
        "bmi": bmi.map((x) => x.toJson()).toList(),
        "rewards": rewards.map((x) => x.toJson()).toList(),
        "calories": calories.map((x) => x.toJson()).toList(),
         "professionals": List<dynamic>.from(professionals.map((x) => x.toJson())),
      };
}

class Professional {
    int id;
    String name;
    String email;
    int customerType;
    int isApproved;

    Professional({
        required this.id,
        required this.name,
        required this.email,
        required this.customerType,
        required this.isApproved,
    });

    factory Professional.fromJson(Map<String, dynamic> json) => Professional(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        customerType: json["customerType"],
        isApproved: json["isApproved"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "customerType": customerType,
        "isApproved": isApproved,
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
        id: _asInt(json["id"]) ?? 0,
        name: _asString(json["name"]) ?? "",
        email: _asString(json["email"]) ?? "",
        emailVerifiedAt: _asString(json["email_verified_at"]),
        faceEncoding: _asString(json["face_encoding"]),
        pickleData: _asString(json["pickle_data"]),
        kidneyCondition: _asString(json["kidney_condition"]),
        age: _asInt(json["age"]) ?? 0,
        bmi: _asInt(json["bmi"]) ?? 0,
        gender: _asString(json["gender"]) ?? "",
        height: _asInt(json["height"]) ?? 0,
        weight: _asInt(json["weight"]) ?? 0,
        createdAt: _asString(json["created_at"]) ?? "",
        updatedAt: _asString(json["updated_at"]) ?? "",
        rewardPoints: _asInt(json["reward_points"]) ?? 0,
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

class Appointment {
  final int id;
  final String? patientName;
  final String? doctorName;
  final String? country;
  final String? appointmentDate;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Appointment({
    required this.id,
    this.patientName,
    this.doctorName,
    this.country,
    this.appointmentDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: _asInt(json["id"]) ?? 0,
        patientName: _asString(json["patient_name"]),
        doctorName: _asString(json["doctor_name"]),
        country: _asString(json["country"]),
        appointmentDate: _asString(json["appointment_date"]),
        notes: _asString(json["notes"]),
        createdAt: _asString(json["created_at"]),
        updatedAt: _asString(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "patient_name": patientName,
        "doctor_name": doctorName,
        "country": country,
        "appointment_date": appointmentDate,
        "notes": notes,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class Bmi {
  final int id;
  final int? userId;
  final int? age;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? category;
  final int? inches;
  final int? ft;
  final String? result;
  final String? createdAt;
  final String? updatedAt;

  Bmi({
    required this.id,
    this.userId,
    this.age,
    this.height,
    this.weight,
    this.bmi,
    this.category,
    this.inches,
    this.ft,
    this.result,
    this.createdAt,
    this.updatedAt,
  });

  factory Bmi.fromJson(Map<String, dynamic> json) => Bmi(
        id: _asInt(json["id"]) ?? 0,
        userId: _asInt(json["user_id"]),
        age: _asInt(json["age"]),
        height: _asDouble(json["height"]),
        weight: _asDouble(json["weight"]),
        bmi: _asDouble(json["bmi"]),
        category: _asString(json["category"]),
        inches: _asInt(json["inches"]),
        ft: _asInt(json["ft"]),
        result: _asString(json["result"]),
        createdAt: _asString(json["created_at"]),
        updatedAt: _asString(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "age": age,
        "height": height,
        "weight": weight,
        "bmi": bmi,
        "category": category,
        "inches": inches,
        "ft": ft,
        "result": result,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class Reward {
  final int id;
  final int? userId;
  final String? juiceColor;
  final int? points;
  final String? createdAt;
  final String? updatedAt;

  Reward({
    required this.id,
    this.userId,
    this.juiceColor,
    this.points,
    this.createdAt,
    this.updatedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: _asInt(json["id"]) ?? 0,
        userId: _asInt(json["user_id"]),
        juiceColor: _asString(json["juice_color"]),
        points: _asInt(json["points"]),
        createdAt: _asString(json["created_at"]),
        updatedAt: _asString(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "juice_color": juiceColor,
        "points": points,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class Calorie {
  final int id;
  final int? userId;
  final int? age;
  final String? gender;
  final num? height;
  final num? weight;
  final String? activityLevel;
  final int? calories;
  final int? ft;
  final int? inches;
  final String? createdAt;
  final String? updatedAt;
  final String? result;

  Calorie({
    required this.id,
    this.userId,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.calories,
    this.ft,
    this.inches,
    this.createdAt,
    this.updatedAt,
    this.result,
  });

  factory Calorie.fromJson(Map<String, dynamic> json) => Calorie(
        id: _asInt(json["id"]) ?? 0,
        userId: _asInt(json["user_id"]),
        age: _asInt(json["age"]),
        gender: _asString(json["gender"]),
        height: _asNum(json["height"]),
        weight: _asNum(json["weight"]),
        activityLevel: _asString(json["activity_level"]),
        calories: _asInt(json["calories"]),
        ft: _asInt(json["ft"]),
        inches: _asInt(json["inches"]),
        createdAt: _asString(json["created_at"]),
        updatedAt: _asString(json["updated_at"]),
        result: _asString(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "age": age,
        "gender": gender,
        "height": height,
        "weight": weight,
        "activity_level": activityLevel,
        "calories": calories,
        "ft": ft,
        "inches": inches,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "result": result,
      };
}

/* ---------- safe casting helpers ---------- */
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String? _asString(dynamic v) => v?.toString();

