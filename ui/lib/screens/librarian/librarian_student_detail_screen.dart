import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/student_service.dart';
import '../../data/services/borrow_service.dart';
import '../../data/services/book_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_preview_dialog.dart';
import 'librarian_book_scanner_view.dart';

class LibrarianStudentDetailScreen extends StatefulWidget {
  final StudentModel student;
  final String token;

  const LibrarianStudentDetailScreen({
    super.key,
    required this.student,
    required this.token,
  });

  @override
  State<LibrarianStudentDetailScreen> createState() =>
      _LibrarianStudentDetailScreenState();
}

class _LibrarianStudentDetailScreenState
    extends State<LibrarianStudentDetailScreen> {
  late StudentService _studentService;
  late BookService _bookService;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _studentData;
  List<TransactionModel> _transactions = [];
  int _returnedPage = 1;
  static const int _returnedItemsPerPage = 3;
  final Map<String, String> _bookCoverCache = {}; // Cache for book covers

  @override
  void initState() {
    super.initState();
    _studentService = StudentService(widget.token);
    _bookService = BookService(widget.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _studentService
          .getStudentWithHistory(widget.student.registration);
      if (mounted) {
        setState(() {
          _studentData = data;
          // Parse transactions if available
          if (data['transactions'] != null) {
            _transactions = (data['transactions'] as List)
                .map((t) {
                  final jsonMap = jsonDecode(jsonEncode(t)) as Map<String, dynamic>;
                  return TransactionModel.fromJson(jsonMap);
                })
                .toList();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _returnBook(TransactionModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Return Book', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Mark "${t.bookTitle ?? 'this book'}" as returned?',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Return'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final user = context.read<AuthProvider>().user!;
      try {
        await BorrowService(user.token).returnBook(bookId: t.bookId, studentReg: t.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book returned successfully'), backgroundColor: AppColors.success));
        }
        // Reload data after successful return
        try {
          await _load();
        } catch (e) {
          // Silently fail for reload, don't show error if return was successful
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LibrarianBookScannerView(student: widget.student),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error != null
              ? _errorWidget()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStudentHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildStudentInfoCard(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 24),
                            _buildBookHistorySection(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    final student = widget.student;
    final color = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              student.photoUrl != null && student.photoUrl!.isNotEmpty
                  ? GestureDetector(
                      onTap: () => showImagePreview(context, student.photoUrl!),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(student.photoUrl!),
                        onBackgroundImageError: (exception, stackTrace) {},
                        child: Container(),
                      ),
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        student.initials,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.registration,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.department,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.session,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    final student = widget.student;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoRow('Roll Number', student.roll),
          const Divider(color: Color(0xFF2A3550), height: 16),
          _infoRow('Email', student.email),
          const Divider(color: Color(0xFF2A3550), height: 16),
          _infoRow('Contact', student.contactNumber),
          const Divider(color: Color(0xFF2A3550), height: 16),
          _infoRow('Address', student.address),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: value != null ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final activeBorrows = _transactions
        .where((t) => t.status == 'ISSUED' || t.status == 'OVERDUE')
        .length;
    final overdue =
        _transactions.where((t) => t.status == 'OVERDUE').length;
    final returned = _transactions.where((t) => t.status == 'RETURNED').length;
    final pending = _transactions.where((t) => t.status == 'REQUESTED').length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Active Books',
            activeBorrows.toString(),
            AppColors.accent,
            Icons.book,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Overdue',
            overdue.toString(),
            AppColors.error,
            Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookHistorySection() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3550)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No Book History',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This student hasn\'t borrowed any books yet',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by status
    final activeTransactions =
        _transactions.where((t) => t.status == 'ISSUED' || t.status == 'OVERDUE').toList();
    final overdueTransactions =
        _transactions.where((t) => t.status == 'OVERDUE').toList();
    final returnedTransactions =
        _transactions.where((t) => t.status == 'RETURNED').toList();
    final requestedTransactions =
        _transactions.where((t) => t.status == 'REQUESTED').toList();

    // Pagination for returned transactions
    final totalReturnedPages = (returnedTransactions.length / _returnedItemsPerPage).ceil();
    if (totalReturnedPages > 0 && _returnedPage > totalReturnedPages) {
      _returnedPage = totalReturnedPages;
    }
    final returnedStartIndex = (_returnedPage - 1) * _returnedItemsPerPage;
    final returnedEndIndex = (returnedStartIndex + _returnedItemsPerPage).clamp(0, returnedTransactions.length);
    final paginatedReturned = returnedTransactions.sublist(returnedStartIndex, returnedEndIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Currently Held Books (${activeTransactions.length})',
            AppColors.accent,
          ),
          const SizedBox(height: 12),
          ..._buildTransactionsList(activeTransactions, showOverdueWarning: true),
          const SizedBox(height: 20),
        ],
        if (overdueTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Overdue Books (${overdueTransactions.length})',
            AppColors.error,
          ),
          const SizedBox(height: 12),
          ..._buildTransactionsList(overdueTransactions),
          const SizedBox(height: 20),
        ],
        if (requestedTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Pending Requests (${requestedTransactions.length})',
            AppColors.gold,
          ),
          const SizedBox(height: 12),
          ..._buildTransactionsList(requestedTransactions),
          const SizedBox(height: 20),
        ],
        if (returnedTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Returned Books (${returnedTransactions.length})',
            AppColors.success,
          ),
          const SizedBox(height: 12),
          ..._buildTransactionsList(paginatedReturned),
          if (totalReturnedPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _returnedPage > 1
                      ? () => setState(() => _returnedPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  color: _returnedPage > 1 ? AppColors.success : AppColors.textMuted,
                ),
                Text(
                  'Page $_returnedPage of $totalReturnedPages',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: _returnedPage < totalReturnedPages
                      ? () => setState(() => _returnedPage++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  color: _returnedPage < totalReturnedPages ? AppColors.success : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransactionsList(
    List<TransactionModel> transactions, {
    bool showOverdueWarning = false,
  }) {
    return transactions
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _transactionCard(t, showOverdueWarning: showOverdueWarning),
          ),
        )
        .toList();
  }

  Widget _transactionCard(
    TransactionModel t, {
    bool showOverdueWarning = false,
  }) {
    final statusColor = t.isOverdue
        ? AppColors.error
        : t.isReturned
            ? AppColors.success
            : t.isRequested
                ? AppColors.gold
                : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.isOverdue
              ? AppColors.error.withOpacity(0.3)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String?>(
                future: _getBookCoverUrl(t.bookId),
                builder: (context, snapshot) {
                  return Container(
                    width: 56,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A3550)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? Icon(
                              Icons.book_rounded,
                              color: AppColors.textMuted,
                              size: 28,
                            )
                          : snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty
                              ? Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.book_rounded,
                                    color: AppColors.textMuted,
                                    size: 28,
                                  ),
                                )
                              : Icon(
                                  Icons.book_rounded,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.bookTitle ?? 'Unknown Book',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (t.bookAuthor != null && t.bookAuthor!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.bookAuthor!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _transactionInfo(
                'Borrowed',
                DateFormat('MMM d, yyyy').format(t.borrowDate),
              ),
              _transactionInfo(
                'Due',
                DateFormat('MMM d, yyyy').format(t.dueDate),
              ),
              if (t.returnDate != null)
                _transactionInfo(
                  'Returned',
                  DateFormat('MMM d, yyyy').format(t.returnDate!),
                ),
            ],
          ),
          if (showOverdueWarning && t.isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overdue by ${t.daysOverdue} day${t.daysOverdue != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (t.isIssued || t.isOverdue) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _returnBook(t),
                icon: const Icon(Icons.assignment_return_rounded, size: 18),
                label: const Text('Mark as Returned'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transactionInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getBookCoverUrl(String bookId) async {
    // Check cache first
    if (_bookCoverCache.containsKey(bookId)) {
      return _bookCoverCache[bookId];
    }

    try {
      final book = await _bookService.getBookById(bookId);
      final coverUrl = book.coverUrl ?? '';
      _bookCoverCache[bookId] = coverUrl;
      return coverUrl;
    } catch (e) {
      // Return null if book fetch fails
      return null;
    }
  }
}
