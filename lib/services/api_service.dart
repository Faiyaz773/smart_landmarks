import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/landmark.dart';

/// Thrown when the server responds with {"error": "..."}.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  Uri _uri(String action, [Map<String, String>? extra]) {
    return Uri.parse(AppConstants.apiBase).replace(queryParameters: {
      'action': action,
      'key': AppConstants.apiKey,
      ...?extra,
    });
  }

  void _checkError(http.Response res) {
    if (res.statusCode == 403) {
      throw ApiException('Invalid or expired key', 403);
    }
    if (res.statusCode >= 400) {
      String msg = 'Request failed';
      try {
        final body = jsonDecode(res.body);
        msg = body['error']?.toString() ?? msg;
      } catch (_) {}
      throw ApiException(msg, res.statusCode);
    }
  }

  /// 1. GET landmarks
  Future<List<Landmark>> getLandmarks() async {
    final res = await http.get(_uri('get_landmarks'));
    _checkError(res);
    final List data = jsonDecode(res.body);
    return data.map((e) => Landmark.fromApi(e)).toList();
  }

  /// 2. POST visit_landmark -> returns job_id (async, not the distance)
  Future<int> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
  }) async {
    final res = await http.post(
      _uri('visit_landmark'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'landmark_id': landmarkId,
        'user_lat': userLat,
        'user_lon': userLon,
      }),
    );
    _checkError(res);
    final body = jsonDecode(res.body);
    return int.parse(body['job_id'].toString());
  }

  /// 3. GET job status - poll this until status == done/failed
  Future<Map<String, dynamic>> getJobStatus(int jobId) async {
    final res = await http.get(_uri('get_job_status', {'job_id': '$jobId'}));
    _checkError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 4. POST create_landmark - MUST be multipart/form-data (server reads
  /// the image via PHP's $_FILES, which is empty for raw JSON bodies).
  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest('POST', _uri('create_landmark'));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkError(res);
    final body = jsonDecode(res.body);
    return int.parse(body['id'].toString());
  }

  /// 5. POST delete_landmark (soft delete) - form-urlencoded
  Future<void> deleteLandmark(int id) async {
    final res = await http.post(_uri('delete_landmark'), body: {'id': '$id'});
    _checkError(res);
  }

  /// 6. POST restore_landmark - form-urlencoded
  Future<void> restoreLandmark(int id) async {
    final res =
        await http.post(_uri('restore_landmark'), body: {'id': '$id'});
    _checkError(res);
  }
}
