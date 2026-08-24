import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../some_fuv.dart';

class MediaService {
  static const String baseUrl = 'http://$apiBackendUrl:$apiBackendPort';

  /// Uploads bytes rather than a local path, so the same method works on web.
  static Future<Map<String, dynamic>> uploadOrGetMediaBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final fileHash = sha256.convert(bytes).toString();

    final checkResponse = await http.post(
      Uri.parse('$baseUrl/media/check_hash'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file_hash': fileHash}),
    );

    if (checkResponse.statusCode == 200) {
      final checkData = jsonDecode(checkResponse.body);
      if (checkData['exists'] == true) {
        return Map<String, dynamic>.from(checkData);
      }
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/media/upload'),
    );
    request.fields['file_hash'] = fileHash;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Ошибка загрузки файла на сервер');
  }
}
