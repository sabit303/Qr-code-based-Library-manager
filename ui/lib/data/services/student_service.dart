import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';
import '../../core/constants/api_constants.dart';

class StudentService {
  final String token;
  StudentService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse(ApiConstants.students)
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final studentsJson = data['data']['students'] as List;
      return {
        'students': studentsJson.map((j) => StudentModel.fromJson(j)).toList(),
        'total': data['data']['total'] ?? 0,
      };
    }
    throw Exception(data['message'] ?? 'Failed to fetch students');
  }

  Future<StudentModel> getStudentById(String id) async {
    final response = await http.get(
        Uri.parse(ApiConstants.studentById(id)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return StudentModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch student');
  }

  Future<StudentModel> getStudentByQrCode(String qrCode) async {
    final response = await http.get(
        Uri.parse(ApiConstants.studentByQrCode(qrCode)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return StudentModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Student not found');
  }

  Future<StudentModel> createStudent(Map<String, dynamic> studentData) async {
    final response = await http.post(
      Uri.parse(ApiConstants.students),
      headers: _headers,
      body: jsonEncode(studentData),
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return StudentModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create student');
  }

  Future<StudentModel> updateStudent(
      String id, Map<String, dynamic> studentData) async {
    final response = await http.put(
      Uri.parse(ApiConstants.studentById(id)),
      headers: _headers,
      body: jsonEncode(studentData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return StudentModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update student');
  }

  Future<void> deleteStudent(String id) async {
    final response = await http.delete(
        Uri.parse(ApiConstants.studentById(id)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete student');
    }
  }

  Future<String> generateQrCode(String id) async {
    final response = await http.post(
        Uri.parse(ApiConstants.studentQrCode(id)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['qrCode'] as String;
    }
    throw Exception(data['message'] ?? 'Failed to generate QR code');
  }

  Future<Map<String, dynamic>> getStudentWithHistory(String registration) async {
    final response = await http.get(
        Uri.parse(ApiConstants.studentScan(registration)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to fetch student details');
  }
}
