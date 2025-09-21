import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../Model/scanjuicemodel.dart';

final box = GetStorage();
var token = box.read('auth_token');

class RetinaApiHttp {
  // >>> Configure these <<<
  static const String _baseUrl = 'https://doctorsipe.com';
  String _token = token;

  /// If their server requires cookies, add them here (optional):
  /// static const String _cookie = 'XSRF-TOKEN=...; retina_session=...';

  Future<ScanJuiceResponse> scanJuiceGlass(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/retina/api/bmi/scan_juice_glass');

    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $_token';
    // ..headers['Cookie'] = _cookie; // uncomment if required

    final filename = p.basename(imageFile.path);
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path,
        filename: filename));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Remote error ${resp.statusCode}: ${resp.body}');
    }

    final body = resp.body.isEmpty ? '{}' : resp.body;
    final data = jsonDecode(body);
    if (data is Map<String, dynamic>) {
      return ScanJuiceResponse.fromMap(data);
    }
    throw Exception('Unexpected response format');
  }
}
