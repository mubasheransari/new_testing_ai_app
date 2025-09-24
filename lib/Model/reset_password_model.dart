import 'dart:convert';

ResetPasswordResponse resetPasswordResponseFromJson(String str) =>
    ResetPasswordResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String resetPasswordResponseToJson(ResetPasswordResponse data) =>
    json.encode(data.toJson());

class ResetPasswordResponse {
  final bool status;
  final String message;

  const ResetPasswordResponse({
    required this.status,
    required this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    // Accept bool or 0/1 just in case
    final boolStatus = rawStatus is bool
        ? rawStatus
        : (rawStatus is num ? rawStatus != 0 : false);

    return ResetPasswordResponse(
      status: boolStatus,
      message: (json['message'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
      };

  ResetPasswordResponse copyWith({
    bool? status,
    String? message,
  }) =>
      ResetPasswordResponse(
        status: status ?? this.status,
        message: message ?? this.message,
      );
}
