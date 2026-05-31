import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/book_provider.dart';
import '../../../data/models/book_model.dart';
import '../../../data/services/book_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/image_preview_dialog.dart';

class StudentBooksTab extends StatefulWidget {
  const StudentBooksTab({super.key});

  @override
  State<StudentBooksTab> createState() => _StudentBooksTabState();
}

class _StudentBooksTabState extends State<StudentBooksTab> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'All', 'Computer Science', 'Mathematics', 'Physics',
    'Chemistry', 'Biology', 'Literature', 'History', 'Engineering',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooks());
  }

  Future<void> _loadBooks({bool refresh = true}) async {
    final user = context.read<AuthProvider>().user!;
    await context.read<BookProvider>().fetchBooks(user.token, refresh: refresh);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Browse Books',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SearchBarWidget(
              hint: 'Search books, authors...',
              controller: _searchCtrl,
              onChanged: (q) {
                context.read<BookProvider>().setSearch(q);
                _loadBooks();
              },
            ),
          ),
          _buildCategoryFilter(),
          Expanded(
            child: bookProvider.isLoading && bookProvider.books.isEmpty
                ? _buildLoadingGrid()
                : bookProvider.error != null
                    ? _buildError(bookProvider.error!)
                    : bookProvider.books.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: () => _loadBooks(),
                            color: AppColors.primary,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: bookProvider.books.length,
                              itemBuilder: (ctx, i) =>
                                  _buildBookCard(bookProvider.books[i], i),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected =
              (_selectedCategory == null && cat == 'All') ||
              _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = cat == 'All' ? null : cat;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(BookModel book, int index) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showBookDetail(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                ? GestureDetector(
                    onTap: () => showImagePreview(context, book.coverUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _bookGradient(index),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.auto_stories_rounded,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _bookGradient(index),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_stories_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: GoogleFonts.inter(
              fontSize: 13,
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
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (book.category != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.category!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: book.isAvailable
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: book.isAvailable
                      ? null
                      : BookService(context.read<AuthProvider>().user!.token)
                          .getAvailability(book.id),
                  builder: (context, snapshot) {
                    if (book.isAvailable) {
                      return Text(
                        '✓ ${book.availableCopies}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }

                    if (snapshot.hasData) {
                      final nextDate =
                          snapshot.data!['nextAvailableDate'];
                      if (nextDate != null) {
                        final date = DateTime.parse(nextDate);
                        final formatted =
                            DateFormat('MMM d').format(date);
                        return Text(
                          'Available $formatted',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    }

                    return Text(
                      '✗',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.15);
  }

  List<Color> _bookGradient(int index) {
    // Overhauled book cover placeholders to use distinct deep professional blue/indigo gradients
    final gradients = [
      [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
      [const Color(0xFF0F172A), const Color(0xFF1E293B)],
      [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)],
      [const Color(0xFF1E1B4B), const Color(0xFF4F46E5)],
    ];
    return gradients[index % gradients.length];
  }

  void _showBookDetail(BookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookDetailSheet(book: book),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      padding: const EdgeInsets.all(20),
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) => Center(
        child: Text(error,
            style: const TextStyle(color: AppColors.textSecondary)),
      );

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No books found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
}

class _BookDetailSheet extends StatelessWidget {
  final BookModel book;
  const _BookDetailSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 36),
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
                    ),
                    const SizedBox(height: 4),
                    Text(book.author,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    StatusBadge(
                      label: book.isAvailable
                          ? '${book.availableCopies} Available'
                          : 'Not Available',
                      color: book.isAvailable
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _detail('ISBN', book.isbn ?? '—'),
          _detail('Publisher', book.publisher ?? '—'),
          _detail('Year', book.publishedYear?.toString() ?? '—'),
          _detail('Category', book.category ?? '—'),
          _detail('Total Copies', book.totalCopies.toString()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
