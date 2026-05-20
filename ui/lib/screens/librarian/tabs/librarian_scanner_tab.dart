import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/services/student_service.dart';
import '../../../data/services/borrow_service.dart';
import '../../../data/providers/book_provider.dart';
import '../../../widgets/common_widgets.dart';

enum ScanMode { scanStudent, selectBook, confirm }

class LibrarianScannerTab extends StatefulWidget {
  final bool isActive;
  const LibrarianScannerTab({super.key, this.isActive = false});

  @override
  State<LibrarianScannerTab> createState() => _LibrarianScannerTabState();
}

class _LibrarianScannerTabState extends State<LibrarianScannerTab> {
  late MobileScannerController _controller;
  ScanMode _mode = ScanMode.scanStudent;
  StudentModel? _scannedStudent;
  BookModel? _selectedBook;
  bool _processing = false;
  bool _scannerActive = true;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      torchEnabled: false,
    );
  }

  @override
  void didUpdateWidget(LibrarianScannerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.start();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void deactivate() {
    _controller.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _mode = ScanMode.scanStudent;
      _scannedStudent = null;
      _selectedBook = null;
      _processing = false;
      _scannerActive = true;
      _error = null;
      _success = false;
    });
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (!_scannerActive || _processing) return;
    if (capture.barcodes.isEmpty) return;
    final qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() { _scannerActive = false; _processing = true; _error = null; });

    final user = context.read<AuthProvider>().user!;
    try {
      // QR code contains the registration number, extract it directly
      final registration = qrData.trim();
      final data = await StudentService(user.token).getStudentWithHistory(registration);
      // The returned data contains the student info at root level
      final studentModel = StudentModel.fromJson(data);
      if (mounted) {
        setState(() {
          _scannedStudent = studentModel;
          _mode = ScanMode.selectBook;
          _processing = false;
        });
        await context.read<BookProvider>().fetchBooks(user.token, refresh: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Student not found for this QR code';
          _processing = false;
          _scannerActive = true;
        });
      }
    }
  }

  Future<void> _borrow() async {
    if (_scannedStudent == null || _selectedBook == null) return;
    setState(() => _processing = true);
    final user = context.read<AuthProvider>().user!;
    try {
      // Check if student already has this book issued
      final activeTransactions = await Future.wait([
        BorrowService(user.token).getTransactions('ISSUED'),
        BorrowService(user.token).getTransactions('OVERDUE'),
      ]);
      
      final studentActiveBooks = activeTransactions.expand((list) => list)
          .where((t) => t.studentId == _scannedStudent!.registration)
          .toList();
      
      final alreadyHasBook = studentActiveBooks.any((t) => t.bookId == _selectedBook!.id);
      
      if (alreadyHasBook) {
        setState(() {
          _error = '${_scannedStudent!.name} already has this book';
          _processing = false;
        });
        return;
      }
      
      await BorrowService(user.token).requestBook(
        studentReg: _scannedStudent!.registration,
        bookId: _selectedBook!.id,
      );
      final returnDate = DateTime.now().add(const Duration(days: 30));
      await BorrowService(user.token).confirmBookRequest(
        studentReg: _scannedStudent!.registration,
        bookId: _selectedBook!.id,
        returnDate: returnDate,
      );
      setState(() { _success = true; _processing = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _reset();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('QR Scanner',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          if (_mode != ScanMode.scanStudent)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent, size: 18),
              label: Text('Reset', style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_success) return _buildSuccess();

    return Column(children: [
      _buildStepIndicator(),
      Expanded(child: _buildStep()),
    ]);
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: [
        _step(1, 'Scan QR', _mode.index >= 0),
        _stepLine(_mode.index >= 1),
        _step(2, 'Select Book', _mode.index >= 1),
        _stepLine(_mode.index >= 2),
        _step(3, 'Confirm', _mode.index >= 2),
      ]),
    );
  }

  Widget _step(int n, String label, bool active) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? AppColors.librarianGradient : null,
          color: active ? null : AppColors.bgCard,
          border: Border.all(color: active ? Colors.transparent : const Color(0xFF2A3550), width: 2),
        ),
        child: Center(child: Text('$n',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textMuted))),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 10,
          color: active ? AppColors.accent : AppColors.textMuted,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: active ? AppColors.librarianGradient : null,
          color: active ? null : const Color(0xFF2A3550),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_mode) {
      case ScanMode.scanStudent:
        return _buildScanner();
      case ScanMode.selectBook:
        return _buildBookSelector();
      case ScanMode.confirm:
        return _buildConfirm();
    }
  }

  Widget _buildScanner() {
    return Column(children: [
      Expanded(
        child: Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
            child: MobileScanner(
              controller: _controller,
              onDetect: _onQrDetected,
            ),
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // Scan frame
          Center(
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                _corner(Alignment.topLeft),
                _corner(Alignment.topRight),
                _corner(Alignment.bottomLeft),
                _corner(Alignment.bottomRight),
              ]),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.95, end: 1.0, duration: 1200.ms),
          // Status
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          if (_error != null)
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
                ]),
              ),
            ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.bgPrimary,
        child: Column(children: [
          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 32),
          const SizedBox(height: 8),
          Text('Point camera at student\'s QR code',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    ]);
  }

  Widget _corner(Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: align == Alignment.topLeft || align == Alignment.topRight
                ? const BorderSide(color: AppColors.accent, width: 3) : BorderSide.none,
            bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                ? const BorderSide(color: AppColors.accent, width: 3) : BorderSide.none,
            left: align == Alignment.topLeft || align == Alignment.bottomLeft
                ? const BorderSide(color: AppColors.accent, width: 3) : BorderSide.none,
            right: align == Alignment.topRight || align == Alignment.bottomRight
                ? const BorderSide(color: AppColors.accent, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBookSelector() {
    final books = context.watch<BookProvider>().books.where((b) => b.isAvailable).toList();
    final s = _scannedStudent!;

    return Column(children: [
      // Student info
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.success.withOpacity(0.2),
              child: Text(s.initials, style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${s.department} • Roll: ${s.roll}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Select a book to borrow:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: books.length,
          itemBuilder: (_, i) {
            final book = books[i];
            final isSelected = _selectedBook?.id == book.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedBook = book;
                _mode = ScanMode.confirm;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFF2A3550),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(book.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(book.author, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                  StatusBadge(label: '${book.availableCopies} avail.', color: AppColors.success),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildConfirm() {
    final s = _scannedStudent!;
    final b = _selectedBook!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Icon(Icons.assignment_rounded, color: AppColors.accent, size: 56),
        const SizedBox(height: 16),
        Text('Confirm Borrowing', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(children: [
            _confirmRow('Student', s.name),
            _confirmRow('Roll', s.roll),
            _confirmRow('Department', s.department),
            const Divider(color: Color(0xFF2A3550)),
            _confirmRow('Book', b.title),
            _confirmRow('Author', b.author),
            if (b.category != null) _confirmRow('Category', b.category!),
            _confirmRow('Available', '${b.availableCopies}/${b.totalCopies}'),
          ]),
        ),
        const SizedBox(height: 16),
        if (_error != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Confirm Borrow',
          onTap: _borrow,
          gradient: AppColors.librarianGradient,
          icon: Icons.check_circle_rounded,
          isLoading: _processing,
          height: 54,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() { _mode = ScanMode.selectBook; _error = null; }),
          child: Text('← Change Book', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        ),
      ]),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.4), blurRadius: 30, spreadRadius: 4)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
        ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Book Borrowed!', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))
            .animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text('Transaction completed successfully',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))
            .animate().fadeIn(delay: 400.ms),
      ]),
    );
  }
}
