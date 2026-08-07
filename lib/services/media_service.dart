import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../some_fuv.dart';

class MediaService {
  static const String baseUrl = 'http://$apiBackendUrl:$apiBackendPort';

  // 1. Быстрое вычисление SHA-256 хэша файла
  static Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  // 2. Дедуплицированная загрузка файла
  static Future<Map<String, dynamic>> uploadOrGetMedia(File file, String fileName) async {
    // Шаг А: Вычисляем SHA-256
    final fileHash = await calculateSha256(file);

    // Шаг Б: Спрашиваем бэкенд, есть ли уже такой файл
    final checkResponse = await http.post(
      Uri.parse('$baseUrl/media/check_hash'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file_hash': fileHash}),
    );

    if (checkResponse.statusCode == 200) {
      final checkData = jsonDecode(checkResponse.body);
      
      // МГНОВЕННЫЙ ОТВЕТ: Если файл уже есть на сервере!
      if (checkData['exists'] == true) {
        return checkData;
      }
    }

    // Шаг В: Если файла нет — загружаем его кусками (Multipart)
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/media/upload'));
    request.fields['file_hash'] = fileHash;
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка загрузки файла на сервер');
    }
  }
}