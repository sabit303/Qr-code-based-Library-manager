import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/services/borrow_service.dart';
import '../../../data/services/student_service.dart';
import '../../../widgets/common_widgets.dart';
import '../librarian_student_detail_screen.dart';

class LibrarianTransactionsTab extends StatefulWidget {
  final int initialTabIndex;

  const LibrarianTransactionsTab({super.key, this.initialTabIndex = 1});

  @override
  State<LibrarianTransactionsTab> createState() => _LibrarianTransactionsTabState();
}

class _LibrarianTransactionsTabState extends State<LibrarianTransactionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;
  static const int _itemsPerPage = 10;
  final Map<int, int> _currentPages = {0: 1, 1: 1, 2: 1}; // Page tracking for each tab

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(LibrarianTransactionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabCtrl.index = widget.initialTabIndex;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user!;
    setState(() => _isLoading = true);
    try {
      final active = await BorrowService(user.token).getTransactions('ISSUED');
      final overdue = await BorrowService(user.token).getTransactions('OVERDUE');
      final requested = await BorrowService(user.token).getTransactions('REQUESTED');
      
      if (mounted) {
        // Sort each list by borrowDate (newest first)
        active.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
        // Sort overdue by days overdue (most overdue first)
        overdue.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
        requested.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
        
        setState(() { 
          _allTransactions = [...requested, ...active, ...overdue]; 
          _isLoading = false; 
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(TransactionModel t) async {
    final user = context.read<AuthProvider>().user!;
    try {
      // Calculate return date as 30 days from now
      final returnDate = DateTime.now().add(const Duration(days: 30));
      await BorrowService(user.token).confirmBookRequest(
        bookId: t.bookId,
        studentReg: t.studentId,
        returnDate: returnDate,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved successfully'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _rejectRequest(TransactionModel t) async {
    final user = context.read<AuthProvider>().user!;
    try {
      await BorrowService(user.token).deleteRequest(bookId: t.bookId, studentReg: t.studentId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected successfully'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requested = _allTransactions.where((t) => t.isRequested).toList();
    final current = _allTransactions.where((t) => t.isIssued).toList();
    final overdue = _allTransactions.where((t) => t.isOverdue).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Loans & Requests',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Requests (${requested.length})'),
            Tab(text: 'Borrowed (${current.length})'),
            Tab(text: 'Overdue (${overdue.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(requested, AppColors.gold, isRequest: true),
                _buildList(current, AppColors.success),
                _buildList(overdue, AppColors.error),
              ],
            ),
    );
  }

  Widget _buildList(List<TransactionModel> items, Color accent, {bool isRequest = false}) {
    final tabIndex = _tabCtrl.index;
    final totalPages = (items.length / _itemsPerPage).ceil();
    final currentPage = _currentPages[tabIndex] ?? 1;
    final startIndex = (currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, items.length);
    final paginatedItems = items.sublist(startIndex, endIndex);
    
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _currentPages[tabIndex] = 1;
              return _load();
            },
            color: AppColors.accent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: paginatedItems.isEmpty
                  ? [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_circle_outline, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No records', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary)),
                          ]),
                        ),
                      ),
                    ]
                  : List.generate(
                      paginatedItems.length,
                      (i) => _buildCard(paginatedItems[i], accent, i, isRequest: isRequest),
                    ),
            ),
          ),
        ),
        if (items.isNotEmpty && totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 1
                      ? () => setState(() => _currentPages[tabIndex] = currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  color: currentPage > 1 ? accent : AppColors.textMuted,
                ),
                Text(
                  'Page $currentPage of $totalPages',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
                IconButton(
                  onPressed: currentPage < totalPages
                      ? () => setState(() => _currentPages[tabIndex] = currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  color: currentPage < totalPages ? accent : AppColors.textMuted,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCard(TransactionModel t, Color accent, int index, {bool isRequest = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.isOverdue ? AppColors.error.withOpacity(0.3) : const Color(0xFF2A3550)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.book_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.bookTitle ?? 'Unknown Book',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (t.bookAuthor != null)
                  Text(t.bookAuthor!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () async {
                    final user = context.read<AuthProvider>().user!;
                    try {
                      final student = await StudentService(user.token).getStudentById(t.studentId);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibrarianStudentDetailScreen(
                              student: student,
                              token: user.token,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not load student details'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Student: ${t.studentName ?? t.studentId}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ]),
            ),
            StatusBadge(
              label: t.statusLabel,
              color: accent,
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A3550), height: 1),
          const SizedBox(height: 12),
          
          if (!isRequest) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _info('Borrowed', DateFormat('MMM d').format(t.borrowDate)),
              _info('Return', DateFormat('MMM d').format(t.dueDate)),
              if (t.isOverdue)
                _info('Overdue', '${t.daysOverdue}d', color: AppColors.error)
              else
                _info('Days Left', '${t.daysUntilDue}d', color: AppColors.success),
            ]),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _returnBook(t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA6), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Mark as Returned', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectRequest(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgPrimary,
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.error),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          ],
        ]),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.1);
  }

  Widget _info(String label, String value, {Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: color ?? AppColors.textSecondary)),
    ]);
  }
}
