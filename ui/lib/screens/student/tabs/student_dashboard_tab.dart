import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/borrow_service.dart';
import '../../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class StudentDashboardTab extends StatefulWidget {
  const StudentDashboardTab({super.key});

  @override
  State<StudentDashboardTab> createState() => _StudentDashboardTabState();
}

class _StudentDashboardTabState extends State<StudentDashboardTab> {
  List<TransactionModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user!;
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
    final user = context.watch<AuthProvider>().user!;
    final borrowed = _history.where((t) => t.isIssued).toList();
    final overdue = _history.where((t) => t.isOverdue).toList();
    final returned = _history.where((t) => t.isReturned).toList();
    final requested = _history.where((t) => t.isRequested).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user.username),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAppBar(user.username),
                  _buildWelcomeBanner(user.username, borrowed.length, overdue.length),
                  const SizedBox(height: 24),
                  _buildStats(borrowed.length, overdue.length, returned.length, requested.length),
                  const SizedBox(height: 28),
                  if (!_isLoading && overdue.isNotEmpty) ...[
                    _buildOverdueWarning(overdue),
                    const SizedBox(height: 24),
                  ],
                  if (!_isLoading && requested.isNotEmpty) ...[
                    const SectionHeader(title: 'Pending Requests'),
                    const SizedBox(height: 14),
                    ...requested.map((t) => _buildPendingCard(t)),
                    const SizedBox(height: 24),
                  ],
                  if (!_isLoading && borrowed.isNotEmpty) ...[
                    const SectionHeader(title: 'Currently Borrowed'),
                    const SizedBox(height: 14),
                    ...borrowed.take(3).map((t) => _buildTransactionCard(t)),
                  ],
                  if (_isLoading) _buildShimmer(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String username) {
    return SliverAppBar(
      backgroundColor: AppColors.bgPrimary,
      expandedHeight: 0,
      floating: true,
      pinned: false,
      actions: [
        IconButton(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeBanner(String username, int borrowed, int overdue) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.studentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${username.split('_').first} 👋',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overdue > 0
                      ? '$overdue book${overdue > 1 ? 's' : ''} overdue!'
                      : borrowed > 0
                          ? '$borrowed book${borrowed > 1 ? 's' : ''} borrowed'
                          : 'No books borrowed',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildStats(int borrowed, int overdue, int returned, int pending) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.76,
      children: [
        StatCard(
          label: 'Borrowed',
          value: borrowed.toString(),
          icon: Icons.book_rounded,
          gradient: AppColors.primaryGradient,
          iconColor: AppColors.primary,
        ),
        StatCard(
          label: 'Pending',
          value: pending.toString(),
          icon: Icons.hourglass_top_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFBB33), Color(0xFFFF8A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: AppColors.accent,
        ),
        StatCard(
          label: 'Overdue',
          value: overdue.toString(),
          icon: Icons.warning_amber_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3D71), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: AppColors.error,
        ),
        StatCard(
          label: 'Returned',
          value: returned.toString(),
          icon: Icons.check_circle_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF00BFA6), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: AppColors.secondary,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildOverdueWarning(List<TransactionModel> overdue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D71), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ${overdue.length} Overdue Book${overdue.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please return them as soon as possible',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdue.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.bookTitle ?? 'Unknown Book',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Overdue by ${t.daysOverdue} day${t.daysOverdue != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Return Now',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildPendingCard(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bookTitle ?? 'Unknown Book',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested: ${DateFormat('MMM d').format(t.borrowDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: 'Pending', color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel t) {
    final isOverdue = t.isOverdue;
    final daysLeft = t.dueDate.difference(DateTime.now()).inDays;
    final statusColor = isOverdue ? AppColors.error : AppColors.success;
    final statusLabel = isOverdue
        ? 'Overdue by ${t.daysOverdue}d'
        : 'Due in ${daysLeft}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.book_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bookTitle ?? 'Unknown Book',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Borrowed: ${DateFormat('MMM d').format(t.borrowDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: statusLabel, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
