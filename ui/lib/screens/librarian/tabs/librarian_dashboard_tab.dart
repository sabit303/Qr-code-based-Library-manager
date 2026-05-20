import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/book_provider.dart';
import '../../../data/providers/student_provider.dart';
import '../../../data/services/borrow_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class LibrarianDashboardTab extends StatefulWidget {
  final Function(int, {int subTabIndex})? onNavigate;

  const LibrarianDashboardTab({super.key, this.onNavigate});

  @override
  State<LibrarianDashboardTab> createState() => _LibrarianDashboardTabState();
}

class _LibrarianDashboardTabState extends State<LibrarianDashboardTab> {
  List<TransactionModel> _activeBorrows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user!;
    setState(() => _isLoading = true);
    try {
      final borrows = await BorrowService(user.token).getTransactions('ISSUED');
      final bookProv = context.read<BookProvider>();
      final studentProv = context.read<StudentProvider>();
      await Future.wait([
        bookProv.fetchBooks(user.token, refresh: true),
        studentProv.fetchStudents(user.token, refresh: true),
      ]);
      if (mounted) setState(() { _activeBorrows = borrows; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final books = context.watch<BookProvider>().books;
    final students = context.watch<StudentProvider>().students;
    final overdue = _activeBorrows.where((t) => t.isOverdue).length;
    final dueSoon = _activeBorrows
        .where((t) => !t.isOverdue && t.daysUntilDue <= 3)
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.bgPrimary,
              floating: true,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Library Dashboard',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
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
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcome(user.username),
                  const SizedBox(height: 24),
                  _buildStatGrid(
                      books.length, students.length,
                      _activeBorrows.length, overdue),
                  const SizedBox(height: 28),
                  if (dueSoon > 0) _buildAlert(dueSoon),
                  if (dueSoon > 0) const SizedBox(height: 20),
                  const SectionHeader(title: 'Recent Borrows'),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    _buildShimmer()
                  else
                    ..._activeBorrows.take(5).map(_buildLoanCard),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(String username) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.librarianGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
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
                  'Welcome, ${username.split('_').first} 📚',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Librarian Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
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
            child: const Icon(Icons.manage_accounts_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildStatGrid(int books, int students, int active, int overdue) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          label: 'Total Books',
          value: books.toString(),
          icon: Icons.library_books_rounded,
          gradient: AppColors.primaryGradient,
          iconColor: AppColors.primary,
          onTap: () => widget.onNavigate?.call(1),
        ),
        StatCard(
          label: 'Students',
          value: students.toString(),
          icon: Icons.people_rounded,
          gradient: AppColors.secondaryGradient,
          iconColor: AppColors.secondary,
          onTap: () => widget.onNavigate?.call(2),
        ),
        StatCard(
          label: 'Active Loans',
          value: active.toString(),
          icon: Icons.book_online_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFBB33), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: AppColors.gold,
          onTap: () => widget.onNavigate?.call(3, subTabIndex: 1),
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
          onTap: () => widget.onNavigate?.call(3, subTabIndex: 2),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildAlert(int dueSoon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$dueSoon book${dueSoon > 1 ? 's' : ''} due within 3 days',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.isOverdue
              ? AppColors.error.withOpacity(0.3)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.book_rounded,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.bookTitle ?? 'Book',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Due: ${DateFormat('MMM d').format(t.dueDate)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(
            label: t.isOverdue ? 'Overdue' : 'Active',
            color: t.isOverdue ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
