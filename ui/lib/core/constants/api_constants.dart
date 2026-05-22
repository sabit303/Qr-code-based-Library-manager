class ApiConstants {
  static const String baseUrl = 'http://localhost:3000';
//  static const String baseUrl = 'https://sabit.me';

  static const String apiUrl = '$baseUrl/api';

  // Auth
  static const String login = '$apiUrl/auth/login';

  // Books
  static const String books = '$apiUrl/books';
  static String bookById(String id) => '$apiUrl/books/$id';
  static String bookByQrCode(String qr) => '$apiUrl/books/qr/$qr';
  static String bookAvailability(String id) => '$apiUrl/books/availability/$id';

  // Students
  static const String students = '$apiUrl/students';
  static String studentById(String id) => '$apiUrl/students/$id';
  static String studentQrCode(String id) => '$apiUrl/students/$id/qrcode';
  static String studentByQrCode(String qr) => '$apiUrl/students/qrcode/$qr';
  static String studentScan(String registration) => '$apiUrl/students/scan/$registration';

  // Borrow
  static const String borrowRequest = '$apiUrl/borrow/request';
  static const String borrowConfirm = '$apiUrl/borrow/confirm';
  static const String borrowReturn = '$apiUrl/borrow/return';
  static const String borrowTransactions = '$apiUrl/borrow/transactions';

  // Librarian
  static const String librarians = '$apiUrl/librarian';
  static String librarianById(String id) => '$apiUrl/librarian/$id';
}
