import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/book_provider.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/borrow_service.dart';
import '../../../widgets/common_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../../widgets/image_preview_dialog.dart';
import '../librarian_book_detail_screen.dart';
import '../librarian_book_scanner_view.dart';

class LibrarianBooksTab extends StatefulWidget {
  const LibrarianBooksTab({super.key});

  @override
  State<LibrarianBooksTab> createState() => _LibrarianBooksTabState();
}

class _LibrarianBooksTabState extends State<LibrarianBooksTab> {
  final _searchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = true}) async {
    final user = context.read<AuthProvider>().user!;
    await context.read<BookProvider>().fetchBooks(user.token, refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>().books;
    final isLoading = context.watch<BookProvider>().isLoading;
    
    final totalPages = (books.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, books.length);
    final paginatedBooks = books.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Manage Books',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SearchBarWidget(
              hint: 'Search books...',
              controller: _searchCtrl,
              onChanged: (q) {
                context.read<BookProvider>().setSearch(q);
                _currentPage = 1;
                _load();
              },
            ),
          ),
          Expanded(
            child: isLoading && books.isEmpty
                ? _loadingList()
                : books.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: () { _currentPage = 1; return _load(); },
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: paginatedBooks.length,
                          itemBuilder: (_, i) => _bookTile(paginatedBooks[i], i),
                        ),
                      ),
          ),
          if (books.isNotEmpty && totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                    color: _currentPage > 1 ? AppColors.accent : AppColors.textMuted,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                    icon: const Icon(Icons.chevron_right),
                    color: _currentPage < totalPages ? AppColors.accent : AppColors.textMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LibrarianBookScannerView()));
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _bookTile(BookModel book, int index) {
    final gradientColors = [
      [const Color(0xFF6C63FF), const Color(0xFF9B5DE5)],
      [const Color(0xFF00BFA6), const Color(0xFF0077B6)],
      [const Color(0xFFFF6B9D), const Color(0xFF9B5DE5)],
      [const Color(0xFFFFBB33), const Color(0xFFFF6B9D)],
    ];
    final c = gradientColors[index % gradientColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          final user = context.read<AuthProvider>().user!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibrarianBookDetailScreen(
                book: book,
                token: user.token,
              ),
            ),
          );
        },
        leading: book.coverUrl != null && book.coverUrl!.isNotEmpty
            ? GestureDetector(
                onTap: () => showImagePreview(context, book.coverUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    book.coverUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              )
            : Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
            ),
        title: Text(book.title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              StatusBadge(
                label: book.isAvailable ? '${book.availableCopies}/${book.totalCopies} avail.' : 'Unavailable',
                color: book.isAvailable ? AppColors.success : AppColors.error,
              ),
              if (book.category != null) ...[
                const SizedBox(width: 6),
                StatusBadge(label: book.category!, color: AppColors.primary),
              ],
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.bgCardLight,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (val) {
            if (val == 'qr') {
              _showQrDialog(book);
            } else if (val == 'edit') {
              _showEditDialog(book);
            } else if (val == 'delete') {
              _confirmDelete(book);
            } else if (val == 'holders') {
              _openBookHistory(book);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'qr',
              child: Row(children: [
                const Icon(Icons.qr_code_2_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Text('Generate QR', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            PopupMenuItem(value: 'holders',
              child: Row(children: [
                const Icon(Icons.group_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Text('Holders & History', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            PopupMenuItem(value: 'edit',
              child: Row(children: [
                const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text('Edit', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            PopupMenuItem(value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Text('Delete', style: GoogleFonts.inter(color: AppColors.error)),
              ])),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideX(begin: 0.1);
  }

  void _showAddDialog() => _openForm(null);
  void _showEditDialog(BookModel book) => _openForm(book);

  void _openForm(BookModel? book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BookFormSheet(
        book: book,
        onSave: (data) async {
          final user = context.read<AuthProvider>().user!;
          if (book == null) {
            await context.read<BookProvider>().createBook(user.token, data);
          } else {
            await context.read<BookProvider>().updateBook(user.token, book.id, data);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BookModel book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Book', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Delete "${book.title}"?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        final user = context.read<AuthProvider>().user!;
        await context.read<BookProvider>().deleteBook(user.token, book.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book deleted'), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _openBookHistory(BookModel book) async {
    final user = context.read<AuthProvider>().user!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookHistorySheet(book: book, token: user.token),
    );
  }

  void _showQrDialog(BookModel book) {
    // Debug check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating QR for ${book.title}...'), duration: const Duration(seconds: 1)),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Book QR Code', 
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: book.id,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        "Uh oh! Something went wrong...",
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(book.title, 
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('ID: ${book.id}', 
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              Text('Students can scan this to request the book',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Right-click the QR code to save as image (Web)')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _loadingList() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12), height: 80,
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
        ),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.library_books_outlined, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No books yet', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showAddDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: Text('Add First Book', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      );
}

// ── Book Form Bottom Sheet ────────────────────────────────────────────────────
class _BookFormSheet extends StatefulWidget {
  final BookModel? book;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _BookFormSheet({this.book, required this.onSave});

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
  final _formKey = GlobalKey<FormState>();
  XFile? _cover;
  final ImagePicker _picker = ImagePicker();
  late final _titleC = TextEditingController(text: widget.book?.title ?? '');
  late final _authorC = TextEditingController(text: widget.book?.author ?? '');
  late final _isbnC = TextEditingController(text: widget.book?.isbn ?? '');
  late final _catC = TextEditingController(text: widget.book?.category ?? '');
  late final _totalC = TextEditingController(text: widget.book?.totalCopies.toString() ?? '1');
  late final _availC = TextEditingController(text: widget.book?.availableCopies.toString() ?? '1');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_titleC, _authorC, _isbnC, _catC, _totalC, _availC]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'Name': _titleC.text.trim(),
        'AuthorName': _authorC.text.trim(),
        if (_isbnC.text.isNotEmpty) 'Edition': _isbnC.text.trim(),
        if (_catC.text.isNotEmpty) 'Genre': _catC.text.trim(),
        'TotalCopies': int.tryParse(_totalC.text) ?? 1,
        'AvailableCopies': int.tryParse(_availC.text) ?? 1,
      };
      
      // Add cover if selected
      if (_cover != null) {
        final bytes = await _cover!.readAsBytes();
        final base64data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        data['coverBase64'] = base64data;
      }
      
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickCover() async {
    final source = kIsWeb ? ImageSource.gallery : ImageSource.gallery;
    final img = await _picker.pickImage(source: source, maxWidth: 1200);
    if (img != null) setState(() => _cover = img);
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {bool req = false, bool num = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        keyboardType: num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        validator: req ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.book != null ? 'Edit Book' : 'Add New Book',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            _f(_titleC, 'Title *', Icons.title_rounded, req: true),
            _f(_authorC, 'Author *', Icons.person_rounded, req: true),
            _f(_isbnC, 'Edition / ISBN', Icons.qr_code_rounded),
            _f(_catC, 'Genre / Category', Icons.category_rounded),
            Row(children: [
              Expanded(child: _f(_totalC, 'Total', Icons.library_books_rounded, num: true)),
              const SizedBox(width: 12),
              Expanded(child: _f(_availC, 'Available', Icons.check_circle_rounded, num: true)),
            ]),
            const SizedBox(height: 16),
            // Cover Photo Picker Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book Cover', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  if (_cover != null) ...[
                    FutureBuilder<Uint8List>(
                      future: _cover!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              snapshot.data!,
                              height: 120,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return const SizedBox(height: 120, width: 80, child: Center(child: CircularProgressIndicator()));
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pickCover,
                    icon: const Icon(Icons.image_rounded, size: 18),
                    label: Text(_cover != null ? 'Change Cover' : 'Select Cover'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GradientButton(
              label: widget.book != null ? 'Update Book' : 'Add Book',
              onTap: _save,
              gradient: AppColors.primaryGradient,
              icon: widget.book != null ? Icons.save_rounded : Icons.add_rounded,
              isLoading: _saving,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ── Book Holders & History Sheet ───────────────────────────────────────────
class _BookHistorySheet extends StatefulWidget {
  final BookModel book;
  final String token;
  const _BookHistorySheet({required this.book, required this.token});

  @override
  State<_BookHistorySheet> createState() => _BookHistorySheetState();
}

class _BookHistorySheetState extends State<_BookHistorySheet> {
  bool _loading = true;
  String? _error;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = BorrowService(widget.token);
      final results = await Future.wait([
        service.getTransactions('ISSUED'),
        service.getTransactions('OVERDUE'),
        service.getTransactions('RETURNED'),
        service.getTransactions('REQUESTED'),
      ]);

      final all = results.expand((i) => i).toList();
      final filtered = all.where((t) => t.bookId == widget.book.id || t.bookTitle == widget.book.title).toList();

      if (mounted) setState(() { _transactions = filtered; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _transactions.where((t) => t.isIssued || t.isOverdue).toList();
    final history = _transactions;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text(widget.book.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('ID: ${widget.book.id}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: _statCard('Held Now', active.length.toString(), AppColors.success)), const SizedBox(width: 12), Expanded(child: _statCard('Total Records', history.length.toString(), AppColors.accent)),]),
            const SizedBox(height: 18),
            Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.accent)) : _error != null ? Center(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary))) : ListView(controller: scrollController, children: [
              _sectionHeader('Current Holders'), const SizedBox(height: 12),
              if (active.isEmpty) _emptyState('No current holders') else ...active.map((t) => _transactionCard(t, showStudent: true)),
              const SizedBox(height: 20),
              _sectionHeader('History'), const SizedBox(height: 12),
              if (history.isEmpty) _emptyState('No history found') else ...history.map((t) => _transactionCard(t, showStudent: true)),
            ])),
          ]),
        );
      }
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3550))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)), const SizedBox(height: 6), Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color))]));
  }

  Widget _sectionHeader(String label) => Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _emptyState(String msg) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3550))), child: Text(msg, style: GoogleFonts.inter(color: AppColors.textSecondary)));

  Widget _transactionCard(TransactionModel t, {bool showStudent = false}) {
    final statusColor = t.isOverdue
        ? AppColors.error
        : t.isReturned
            ? AppColors.success
            : t.isRequested
                ? AppColors.gold
                : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                    ),
                    if (t.studentName != null && showStudent) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Student: ${t.studentName}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reg: ${t.studentRegistration ?? t.studentId}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if ((t.studentDepartment ?? '').isNotEmpty || (t.studentSession ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${t.studentDepartment ?? 'Unknown Department'}${(t.studentDepartment ?? '').isNotEmpty && (t.studentSession ?? '').isNotEmpty ? ' • ' : ''}${t.studentSession ?? ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _mini('Borrowed', DateFormat('MMM d, yyyy').format(t.borrowDate)),
              _mini('Due', DateFormat('MMM d, yyyy').format(t.dueDate)),
              if (t.returnDate != null) _mini('Returned', DateFormat('MMM d, yyyy').format(t.returnDate!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String val) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3550))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('$label: ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)), Text(val, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))]));
}
