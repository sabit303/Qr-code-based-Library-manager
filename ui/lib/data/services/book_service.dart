import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import '../../core/constants/api_constants.dart';

class BookService {
  final String token;
  BookService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri =
        Uri.parse(ApiConstants.books).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final booksJson = data['data']['books'] as List;
      return {
        'books': booksJson.map((j) => BookModel.fromJson(j)).toList(),
        'total': data['data']['total'] ?? 0,
        'page': data['data']['page'] ?? 1,
      };
    }
    throw Exception(data['message'] ?? 'Failed to fetch books');
  }

  Future<BookModel> getBookById(String id) async {
    final response = await http.get(
        Uri.parse(ApiConstants.bookById(id)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return BookModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch book');
  }

  Future<BookModel> getBookByQrCode(String qrCode) async {
    final response = await http.get(
        Uri.parse(ApiConstants.bookByQrCode(qrCode)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return BookModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch book by QR');
  }

  Future<BookModel> createBook(Map<String, dynamic> bookData) async {
    final response = await http.post(
      Uri.parse(ApiConstants.books),
      headers: _headers,
      body: jsonEncode(bookData),
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return BookModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create book');
  }

  Future<BookModel> updateBook(String id, Map<String, dynamic> bookData) async {
    final response = await http.put(
      Uri.parse(ApiConstants.bookById(id)),
      headers: _headers,
      body: jsonEncode(bookData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return BookModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update book');
  }

  Future<void> deleteBook(String id) async {
    final response = await http.delete(
        Uri.parse(ApiConstants.bookById(id)),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete book');
    }
  }
}
