class TransactionModel {
  final String id;
  final String studentId;
  final String bookId;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // borrowed, returned, overdue
  final String? studentName;
  final String? studentRegistration;
  final String? studentDepartment;
  final String? studentSession;
  final String? bookTitle;
  final String? bookAuthor;

  TransactionModel({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.studentName,
    this.studentRegistration,
    this.studentDepartment,
    this.studentSession,
    this.bookTitle,
    this.bookAuthor,
  });

  static String _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static String _normalizeStatus(dynamic value) {
    return value?.toString().trim().toUpperCase() ?? 'REQUESTED';
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _stringValue(json, ['id', 'transactionId']),
      studentId: _stringValue(json, ['studentReg', 'studentId', 'StudentReg']),
      bookId: _stringValue(json, ['bookId', 'bookID']),
      borrowDate: _parseDate(json['borrowedDate'] ?? json['borrowDate']),
      dueDate: _parseDate(json['dueDate']),
      returnDate: json['returnDate'] != null
          ? _parseDate(json['returnDate'])
          : null,
      status: _normalizeStatus(json['status']),
      studentName: json['studentName'] ?? json['student_name'],
      studentRegistration:
          json['studentRegistration'] ?? json['student_registration'],
      studentDepartment:
          json['studentDepartment'] ?? json['student_department'],
      studentSession: json['studentSession'] ?? json['student_session'],
      bookTitle: json['bookTitle'] ?? json['book_title'] ?? json['title'],
      bookAuthor: json['bookAuthor'] ?? json['book_author'] ?? json['author'],
    );
  }

  bool get isOverdue =>
      status == 'OVERDUE' || (status == 'ISSUED' && DateTime.now().isAfter(dueDate));
  bool get isReturned => status == 'RETURNED';
  bool get isIssued => status == 'ISSUED';
  bool get isRequested => status == 'REQUESTED';

  String get statusLabel {
    if (isOverdue) return 'Overdue';
    if (isReturned) return 'Returned';
    if (isRequested) return 'Pending';
    return 'Active';
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  int get daysOverdue => DateTime.now().difference(dueDate).inDays;
}
