import 'dart:convert';

class ScanJuiceResponse {
  final bool success;
  final String? message;
  final String? detectedColor;
  final int? pointsAwarded;
  final int? totalPoints;
  final RetinaUser? user;

  ScanJuiceResponse({
    required this.success,
    this.message,
    this.detectedColor,
    this.pointsAwarded,
    this.totalPoints,
    this.user,
  });

  factory ScanJuiceResponse.fromMap(Map<String, dynamic> map) {
    return ScanJuiceResponse(
      success: map['success'] == true,
      message: map['message'] as String?,
      detectedColor: map['detected_color'] as String?,
      pointsAwarded: _asInt(map['points_awarded']),
      totalPoints: _asInt(map['total_points']),
      user: map['user'] != null ? RetinaUser.fromMap(map['user']) : null,
    );
  }

  factory ScanJuiceResponse.fromJson(String source) =>
      ScanJuiceResponse.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class RetinaUser {
  final int id;
  final String? name;
  final String? email;
  final int? age;
  final String? gender;
  final int? height;
  final int? weight;
  final int? rewardPoints;

  final String? emailVerifiedAt;
  final String? faceEncoding;
  final String? pickleData;
  final String? kidneyCondition;
  final num? bmi;
  final String? createdAt;
  final String? updatedAt;

  RetinaUser({
    required this.id,
    this.name,
    this.email,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.rewardPoints,
    this.emailVerifiedAt,
    this.faceEncoding,
    this.pickleData,
    this.kidneyCondition,
    this.bmi,
    this.createdAt,
    this.updatedAt,
  });

  factory RetinaUser.fromMap(Map<String, dynamic> map) {
    int? _i(dynamic v) =>
        v == null ? null : v is int ? v : v is num ? v.toInt() : int.tryParse('$v');

    return RetinaUser(
      id: _i(map['id']) ?? 0,
      name: map['name'] as String?,
      email: map['email'] as String?,
      age: _i(map['age']),
      gender: map['gender'] as String?,
      height: _i(map['height']),
      weight: _i(map['weight']),
      rewardPoints: _i(map['reward_points']),
      emailVerifiedAt: map['email_verified_at'] as String?,
      faceEncoding: map['face_encoding'] as String?,
      pickleData: map['pickle_data'] as String?,
      kidneyCondition: map['kidney_condition'] as String?,
      bmi: map['bmi'] as num?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
