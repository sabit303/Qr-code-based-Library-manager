import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/borrow_service.dart';
import '../../widgets/image_preview_dialog.dart';

class LibrarianBookDetailScreen extends StatefulWidget {
  final BookModel book;
  final String token;

  const LibrarianBookDetailScreen({
    super.key,
    required this.book,
    required this.token,
  });

  @override
  State<LibrarianBookDetailScreen> createState() =>
      _LibrarianBookDetailScreenState();
}

class _LibrarianBookDetailScreenState extends State<LibrarianBookDetailScreen> {
  late BorrowService _borrowService;
  bool _loading = true;
  String? _error;
  List<TransactionModel> _transactions = [];
  int _returnedPage = 1;
  static const int _returnedItemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _borrowService = BorrowService(widget.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _borrowService.getTransactions('ISSUED'),
        _borrowService.getTransactions('OVERDUE'),
        _borrowService.getTransactions('RETURNED'),
        _borrowService.getTransactions('REQUESTED'),
      ]);
      
      final allTransactions = results.expand((items) => items).toList();
      final filtered = allTransactions.where((t) => t.bookId == widget.book.id).toList();

      if (mounted) {
        setState(() {
          _transactions = filtered;
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
          'Book Details',
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
                      _buildBookHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildBookInfoCard(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 24),
                            _buildBorrowHistorySection(),
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

  Widget _buildBookHeader() {
    final book = widget.book;
    final gradientColors = [
      [const Color(0xFF6C63FF), const Color(0xFF9B5DE5)],
      [const Color(0xFF00BFA6), const Color(0xFF0077B6)],
      [const Color(0xFFFF6B9D), const Color(0xFF9B5DE5)],
      [const Color(0xFFFFBB33), const Color(0xFFFF6B9D)],
    ];
    final colors = gradientColors[0];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[0].withOpacity(0.2),
            colors[1].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: colors[0].withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? GestureDetector(
                      onTap: () => showImagePreview(context, book.coverUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book.coverUrl!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: book.isAvailable
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.isAvailable
                            ? '${book.availableCopies}/${book.totalCopies} available'
                            : 'Not available',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: book.isAvailable
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildBookInfoCard() {
    final book = widget.book;
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
          _infoRow('Title', book.title),
          const Divider(color: Color(0xFF2A3550), height: 16),
          _infoRow('Author', book.author),
          const Divider(color: Color(0xFF2A3550), height: 16),
          if (book.isbn != null)
            ...[
              _infoRow('ISBN', book.isbn),
              const Divider(color: Color(0xFF2A3550), height: 16),
            ],
          if (book.publisher != null)
            ...[
              _infoRow('Publisher', book.publisher),
              const Divider(color: Color(0xFF2A3550), height: 16),
            ],
          if (book.publishedYear != null)
            ...[
              _infoRow('Published', book.publishedYear.toString()),
              const Divider(color: Color(0xFF2A3550), height: 16),
            ],
          if (book.category != null)
            ...[
              _infoRow('Category', book.category),
              const Divider(color: Color(0xFF2A3550), height: 16),
            ],
          _infoRow('Total Copies', book.totalCopies.toString()),
          const Divider(color: Color(0xFF2A3550), height: 16),
          _infoRow('Available Copies', book.availableCopies.toString()),
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
    final activeBorrows =
        _transactions.where((t) => t.status == 'ISSUED').length;
    final overdue = _transactions.where((t) => t.status == 'OVERDUE').length;
    final returned = _transactions.where((t) => t.status == 'RETURNED').length;
    final pending = _transactions.where((t) => t.status == 'REQUESTED').length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Currently Held',
            activeBorrows.toString(),
            AppColors.accent,
            Icons.person,
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

  Widget _buildBorrowHistorySection() {
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
              Icons.people_outline,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No Borrowing History',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No students have borrowed this book',
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
        _transactions.where((t) => t.status == 'ISSUED').toList();
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
            'Currently Held (${activeTransactions.length})',
            AppColors.accent,
          ),
          const SizedBox(height: 12),
          ..._buildBorrowList(activeTransactions, showOverdueWarning: true),
          const SizedBox(height: 20),
        ],
        if (overdueTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Overdue (${overdueTransactions.length})',
            AppColors.error,
          ),
          const SizedBox(height: 12),
          ..._buildBorrowList(overdueTransactions),
          const SizedBox(height: 20),
        ],
        if (requestedTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Pending Requests (${requestedTransactions.length})',
            AppColors.gold,
          ),
          const SizedBox(height: 12),
          ..._buildBorrowList(requestedTransactions),
          const SizedBox(height: 20),
        ],
        if (returnedTransactions.isNotEmpty) ...[
          _sectionHeader(
            'Returned (${returnedTransactions.length})',
            AppColors.success,
          ),
          const SizedBox(height: 12),
          ..._buildBorrowList(paginatedReturned),
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

  List<Widget> _buildBorrowList(
    List<TransactionModel> transactions, {
    bool showOverdueWarning = false,
  }) {
    return transactions
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _borrowCard(t, showOverdueWarning: showOverdueWarning),
          ),
        )
        .toList();
  }

  Widget _borrowCard(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName ?? 'Unknown Student',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (t.studentRegistration != null &&
                        t.studentRegistration!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reg: ${t.studentRegistration}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
}
