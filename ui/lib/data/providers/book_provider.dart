import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  String _searchQuery = '';

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;

  List<BookModel> _booksFromResult(dynamic value) {
    if (value is Iterable) {
      return value.whereType<BookModel>().toList();
    }
    return const [];
  }
  bool get hasMore => _books.length < _total;

  Future<void> fetchBooks(String token, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _books = [];
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await BookService(token).getBooks(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final newBooks = _booksFromResult(result['books']);
      if (refresh) {
        _books = newBooks;
      } else {
        _books.addAll(newBooks);
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

  Future<BookModel> createBook(String token, Map<String, dynamic> data) async {
    final book = await BookService(token).createBook(data);
    _books.insert(0, book);
    _total++;
    notifyListeners();
    return book;
  }

  Future<void> updateBook(
      String token, String id, Map<String, dynamic> data) async {
    final updated = await BookService(token).updateBook(id, data);
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _books[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteBook(String token, String id) async {
    await BookService(token).deleteBook(id);
    _books.removeWhere((b) => b.id == id);
    _total--;
    notifyListeners();
  }
}
