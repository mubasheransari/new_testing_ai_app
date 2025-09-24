import 'dart:convert';
import 'package:motives_tneww/Model/signup_model.dart';
import 'package:http/http.dart' as http;
import '../Model/login_model.dart';

class Repository {
  final String loginUrl = "https://doctorsipe.com/retina/api/login";
  final String signupUrl = "https://doctorsipe.com/retina/api/users";

  Future<LoginModel> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        body: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LoginModel.fromJson(data);
      } else {
        throw Exception(
            "Login failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      throw Exception("Login API failed: $e");
    }
  }

  Future<http.Response> signUp(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("https://doctorsipe.com/retina/api/users"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      // final response = await http.post(
      //   Uri.parse(signupUrl),
      //   body: {
      //     "name":name,
      //     "email": email,
      //     "password": password,
      //   },
      // );

      return response;
    } catch (e) {
      throw Exception("Signup API failed: $e");
    }
  }

  Future<UserResponse> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("https://doctorsipe.com/retina/api/users");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return UserResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to create user: ${response.body}");
    }
  }
}
