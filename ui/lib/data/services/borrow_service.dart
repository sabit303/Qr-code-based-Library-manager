import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../../core/constants/api_constants.dart';

class BorrowService {
  final String token;
  BorrowService(this.token);

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  TransactionModel _transactionFromPayload(dynamic payload) {
    final raw = payload is List && payload.isNotEmpty ? payload.first : payload;
    final transactionJson = _asMap(raw);
    if (transactionJson == null) {
      throw Exception('Invalid transaction response from server');
    }
    return TransactionModel.fromJson(transactionJson);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<TransactionModel> requestBook(
      {required String bookId,
      required String studentReg,
      required DateTime returnDate}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.borrowRequest),
      headers: _headers,
      body: jsonEncode({
        'bookID': bookId,
        'StudentReg': studentReg,
        'returnDate': returnDate.toIso8601String(),
      }),
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return _transactionFromPayload(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to request book');
  }

  Future<TransactionModel> confirmBookRequest(
      {required String bookId, required String studentReg, DateTime? returnDate}) async {
    final body = {'bookID': bookId, 'StudentReg': studentReg};
    if (returnDate != null) {
      body['returnDate'] = returnDate.toIso8601String();
    }
    final response = await http.patch(
      Uri.parse(ApiConstants.borrowConfirm),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return _transactionFromPayload(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to confirm book');
  }

  Future<TransactionModel> returnBook(
      {required String bookId, required String studentReg}) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.borrowReturn),
      headers: _headers,
      body: jsonEncode({'bookID': bookId, 'StudentReg': studentReg}),
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return _transactionFromPayload(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to return book');
  }

  Future<void> deleteRequest(
      {required String bookId, required String studentReg}) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.borrowRequest),
      headers: _headers,
      body: jsonEncode({'bookID': bookId, 'StudentReg': studentReg}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete request');
    }
  }

  Future<List<TransactionModel>> getTransactions(String status) async {
    final response = await http.get(
        Uri.parse('${ApiConstants.borrowTransactions}?status=$status'),
        headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final raw = data['data'];
      final list = raw is Iterable ? raw.toList() : const [];
      return list
          .map((j) {
            final jsonMap = _asMap(j);
            if (jsonMap == null) {
              return null;
            }
            return TransactionModel.fromJson(jsonMap);
          })
          .whereType<TransactionModel>()
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch transactions');
  }
}
