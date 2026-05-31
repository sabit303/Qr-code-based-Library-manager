import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tabs/librarian_dashboard_tab.dart';
import 'tabs/librarian_books_tab.dart';
import 'tabs/librarian_students_tab.dart';
import 'tabs/librarian_transactions_tab.dart';

class LibrarianHome extends StatefulWidget {
  const LibrarianHome({super.key});

  @override
  State<LibrarianHome> createState() => _LibrarianHomeState();
}

class _LibrarianHomeState extends State<LibrarianHome> {
  int _currentIndex = 0;
  int _returnsSubTabIndex = 1; // 0=Requests, 1=Borrowed, 2=Overdue

  void _navigateToTab(int tabIndex, {int subTabIndex = 0}) {
    setState(() {
      _currentIndex = tabIndex;
      if (tabIndex == 3) {
        _returnsSubTabIndex = subTabIndex;
      }
    });
  }

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const LibrarianDashboardTab(),
      const LibrarianBooksTab(),
      const LibrarianStudentsTab(),
      const LibrarianTransactionsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LibrarianDashboardTab(onNavigate: _navigateToTab),
          const LibrarianBooksTab(),
          const LibrarianStudentsTab(),
          LibrarianTransactionsTab(initialTabIndex: _returnsSubTabIndex),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                _navItem(1, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Books'),
                _navItem(2, Icons.people_rounded, Icons.people_outline_rounded, 'Students'),
                _navItem(3, Icons.assignment_return_rounded, Icons.assignment_return_outlined, 'Manage'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? active : inactive,
              color: isSelected ? AppColors.accent : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
