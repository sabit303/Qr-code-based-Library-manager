import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  String _searchQuery = '';

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;

  List<StudentModel> _studentsFromResult(dynamic value) {
    if (value is Iterable) {
      return value.whereType<StudentModel>().toList();
    }
    return const [];
  }

  Future<void> fetchStudents(String token, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _students = [];
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await StudentService(token).getStudents(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final newStudents = _studentsFromResult(result['students']);
      if (refresh) {
        _students = newStudents;
      } else {
        _students.addAll(newStudents);
      }
      _total = result['total'] as int;
      _currentPage++;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
  }

  Future<StudentModel> createStudent(
      String token, Map<String, dynamic> data) async {
    final student = await StudentService(token).createStudent(data);
    _students.insert(0, student);
    _total++;
    notifyListeners();
    return student;
  }

  Future<void> updateStudent(
      String token, String id, Map<String, dynamic> data) async {
    final updated = await StudentService(token).updateStudent(id, data);
    final idx = _students.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _students[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String token, String id) async {
    await StudentService(token).deleteStudent(id);
    _students.removeWhere((s) => s.id == id);
    _total--;
    notifyListeners();
  }

  Future<String> generateQrCode(String token, String id) async {
    final qrUrl = await StudentService(token).generateQrCode(id);
    final idx = _students.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = _students[idx];
      _students[idx] = StudentModel(
        id: updated.id,
        name: updated.name,
        roll: updated.roll,
        registration: updated.registration,
        department: updated.department,
        session: updated.session,
        email: updated.email,
        contactNumber: updated.contactNumber,
        address: updated.address,
        qrCode: qrUrl,
        photoUrl: updated.photoUrl,
        createdAt: updated.createdAt,
      );
      notifyListeners();
    }
    return qrUrl;
  }
}
