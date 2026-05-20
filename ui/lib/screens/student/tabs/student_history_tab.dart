import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/borrow_service.dart';
import '../../../widgets/common_widgets.dart';

class StudentHistoryTab extends StatefulWidget {
  const StudentHistoryTab({super.key});

  @override
  State<StudentHistoryTab> createState() => _StudentHistoryTabState();
}

class _StudentHistoryTabState extends State<StudentHistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<TransactionModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final returned = await BorrowService(user.token).getTransactions('RETURNED');
      final requested = await BorrowService(user.token).getTransactions('REQUESTED');
      
      final history = [...active, ...overdue, ...returned, ...requested];
      if (mounted) setState(() { _history = history; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowed = _history.where((t) => t.isIssued).toList();
    final overdue = _history.where((t) => t.isOverdue).toList();
    final returned = _history.where((t) => t.isReturned).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('My History',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${borrowed.length})'),
            Tab(text: 'Overdue (${overdue.length})'),
            Tab(text: 'Returned'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                if (overdue.isNotEmpty) _buildOverdueAlert(overdue),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(borrowed, AppColors.primary),
                      _buildList(overdue, AppColors.error),
                      _buildList(returned, AppColors.success),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverdueAlert(List<TransactionModel> overdue) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overdue.length} Overdue Book${overdue.length > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please return immediately to avoid penalties',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TransactionModel> items, Color accentColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No records found',
                style: GoogleFonts.inter(
                    fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i], accentColor, i),
      ),
    );
  }

  Widget _buildCard(TransactionModel t, Color accentColor, int index) {
    final isOverdue = t.isOverdue;
    final isReturned = t.isReturned;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.35)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.book_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.bookTitle ?? 'Unknown Book',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (t.bookAuthor != null)
                        Text(t.bookAuthor!,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                StatusBadge(
                  label: t.statusLabel,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A3550), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dateInfo('Borrowed',
                    DateFormat('MMM d, yyyy').format(t.borrowDate)),
                _dateInfo('Due Date',
                    DateFormat('MMM d, yyyy').format(t.dueDate)),
                if (isReturned && t.returnDate != null)
                  _dateInfo('Returned',
                      DateFormat('MMM d').format(t.returnDate!)),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 16),
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
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: -0.1);
  }

  Widget _dateInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}
