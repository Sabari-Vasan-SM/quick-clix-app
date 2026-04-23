import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:quickclix/config/app_config.dart';
import 'package:quickclix/models/retrieve_result.dart';
import 'package:quickclix/models/upload_kind.dart';
import 'package:quickclix/models/upload_receipt.dart';

class ClipboardApiService {
  ClipboardApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<UploadReceipt> upload({
    required UploadKind kind,
    String? text,
    PlatformFile? file,
  }) async {
    final request = http.MultipartRequest('POST', AppConfig.uploadUri);

    if (kind == UploadKind.text) {
      request.fields['text'] = (text ?? '').trim();
    } else {
      if (file == null) {
        throw Exception('Please choose a file to upload.');
      }
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('Unable to read selected file.');
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _parseResponse(response);

    if (!_isSuccessful(response.statusCode)) {
      throw Exception(payload['message'] ?? 'Upload failed.');
    }

    return UploadReceipt.fromJson(payload);
  }

  Future<RetrieveResult> retrieve(String pin) async {
    final response = await _client.post(
      AppConfig.retrieveUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pin': pin}),
    );
    final payload = await _parseResponse(response);

    if (!_isSuccessful(response.statusCode)) {
      throw Exception(payload['message'] ?? 'Could not retrieve content.');
    }

    return RetrieveResult.fromJson(payload);
  }

  Future<List<int>> downloadByPath(String downloadPath) async {
    final response = await _client.get(AppConfig.resolveApiPath(downloadPath));

    if (!_isSuccessful(response.statusCode)) {
      final payload = await _parseResponse(response);
      throw Exception(payload['message'] ?? 'Download failed.');
    }

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final message = response.body.trim().isEmpty
        ? '${response.statusCode} ${response.reasonPhrase ?? ''}'.trim()
        : response.body.trim();
    return {'message': message};
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
