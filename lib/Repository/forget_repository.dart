// import 'dart:convert';
// import 'package:http/http.dart' as http;

// import '../Model/reset_password_model.dart';

// Future<ResetPasswordResponse> requestPasswordResetHttp(String email) async {
//   final uri = Uri.parse('https://cartforble.com/api/restore-password');
//   final r = await http.post(
//     uri,
//     headers: {
//       'Accept': 'application/json',
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({'email': email}),
//   );

//   if (r.statusCode >= 200 && r.statusCode < 300) {
//     final map = jsonDecode(r.body) as Map<String, dynamic>;
//     return ResetPasswordResponse.fromJson(map);
//   } else {
//     try {
//       final map = jsonDecode(r.body) as Map<String, dynamic>;
//       throw Exception(map['message'] ?? 'Request failed (${r.statusCode})');
//     } catch (_) {
//       throw Exception('Request failed (${r.statusCode})');
//     }
//   }
// }
