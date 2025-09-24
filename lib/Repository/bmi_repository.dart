import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class BmiRepository {
  static const _endpoint = "https://doctorsipe.com/retina/api/bmi";

  /// Make sure you've called: `await GetStorage.init();` in main()
  Future<Map<String, dynamic>> createBmi({
    required int age,
    required double height,
    required double weight,
    required int ft,
    required int inches,
    required num result, // can be int/double; will send as String
  }) async {
    final box = GetStorage();
    final token = box.read<String>('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("No auth token found in storage (auth_token).");
    }

    final url = Uri.parse(_endpoint);

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "Accept": "application/json",
      // Helps Laravel treat it as an AJAX/API request (prevents HTML redirects)
      "X-Requested-With": "XMLHttpRequest",
    };

    final payload = {
      "age": age,
      "height": height,
      "weight": weight,
      "ft": ft,
      "inches": inches,
      // API returned "result" as string in your sample response
      "result": result.toString(),
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    print("📡 BMI API Status Code: ${response.statusCode}");
    print("📦 BMI API Raw Body: ${response.body}");

    // Helpful diagnostics for redirect/auth issues
    if (response.statusCode == 302) {
      final loc = response.headers['location'] ?? 'unknown';
      throw Exception("Got 302 redirect to $loc. Likely auth/headers issue.");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        "Failed to create BMI: ${response.statusCode} ${response.body}",
      );
    }
  }
}




// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;

// final box = GetStorage();
// var token = box.read('auth_token');

// class BmiRepository {
//   final String _baseUrl = "https://doctorsipe.com/retina/api/bmi";
//   // final String _token =
//   //     "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."; // replace with your JWT

//   Future<Map<String, dynamic>> createBmi({
//     required int age,
//     required double height,
//     required double weight,
//     required int ft,
//     required int inches,
//     required int result,
//   }) async {
//     final url = Uri.parse(_baseUrl);

//     final response = await http.post(
//       url,
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "age": age,
//         "height": height,
//         "weight": weight,
//         "ft": ft,
//         "inches": inches,
//         "result": result,
//       }),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(
//           "Failed to create BMI: ${response.statusCode} ${response.body}");
//     }
//   }
// }
