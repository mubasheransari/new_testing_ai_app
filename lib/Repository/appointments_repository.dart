import 'dart:convert';
import 'package:http/http.dart' as http;

class AppointmentsRepo {
  static const String _baseUrl = 'https://doctorsipe.com/retina/api';

  Future<Map<String, dynamic>> createAppointment({
    required String jwtToken,
    required String patientName,
    required String doctorName,
    String? country, // optional
    required String appointmentDate, // "2025-09-01"
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/appointments');

      final payload = <String, dynamic>{
        "patient_name": patientName,
        "doctor_name": doctorName,
        "appointment_date": appointmentDate,
        "country": country,
        "notes": notes,
        // if (country != null && country.trim().isNotEmpty) "country": country.trim(),
        // if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
      };

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $jwtToken",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("STATUS CODE200 BODY PRINT $body");
         print("STATUS CODE200 BODY PRINT $body");
          print("STATUS CODE200 BODY PRINT $body");
        // return decoded response (change to your model if you have one)
        return (body is Map<String, dynamic>) ? body : {"data": body};
      }

      if (response.statusCode == 401) {
        throw Exception("Unauthorized (401): Token invalid/expired.");
      }

      throw Exception("Create appointment failed: ${response.statusCode} ${response.body}");
    } catch (e) {
      throw Exception("Create appointment API failed: $e");
    }
  }
}
