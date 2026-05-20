import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/book_service.dart';
import '../../data/services/borrow_service.dart';
import '../../widgets/common_widgets.dart';
import 'librarian_book_detail_screen.dart';

class LibrarianBookScannerView extends StatefulWidget {
  final StudentModel? student;
  const LibrarianBookScannerView({super.key, this.student});

  @override
  State<LibrarianBookScannerView> createState() =>
      _LibrarianBookScannerViewState();
}

class _LibrarianBookScannerViewState extends State<LibrarianBookScannerView> {
  late MobileScannerController cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(autoStart: true);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.student != null ? 'Issue Book to ${widget.student!.name}' : 'Scan Book QR',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                const Spacer(),
                // Scanner frame
                Container(
                  height: 280,
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: CornersPainter(),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Position the QR code within the frame',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String qrCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final token = context.read<AuthProvider>().user!.token;
      final bookService = BookService(token);
      final borrowService = BorrowService(token);

      // QR code contains the book ID
      final bookId = qrCode.trim();
      
      // Get book by ID
      final book = await bookService.getBookById(bookId);

      // If student is provided, auto-issue the book
      if (widget.student != null) {
        // Check if student already has this book issued
        final activeTransactions = await Future.wait([
          borrowService.getTransactions('ISSUED'),
          borrowService.getTransactions('OVERDUE'),
        ]);
        
        final studentActiveBooks = activeTransactions.expand((list) => list)
            .where((t) => t.studentId == widget.student!.registration)
            .toList();
        
        final alreadyHasBook = studentActiveBooks.any((t) => t.bookId == book.id);
        
        if (alreadyHasBook) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.student!.name} already has this book'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        
        await borrowService.requestBook(
          bookId: book.id,
          studentReg: widget.student!.registration,
        );
        final returnDate = DateTime.now().add(const Duration(days: 30));
        await borrowService.confirmBookRequest(
          bookId: book.id,
          studentReg: widget.student!.registration,
          returnDate: returnDate,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Book "${book.title}" issued to ${widget.student!.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          cameraController.stop();
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            cameraController.start();
          }
        }
      } else {
        // Fetch all transactions to filter for this book
        final results = await Future.wait([
          borrowService.getTransactions('ISSUED'),
          borrowService.getTransactions('OVERDUE'),
          borrowService.getTransactions('RETURNED'),
          borrowService.getTransactions('REQUESTED'),
        ]);

        final allTransactions = results.expand((items) => items).toList();
        final bookTransactions =
            allTransactions.where((t) => t.bookId == book.id).toList();

        if (mounted) {
          cameraController.stop();
          await _showBookDetailsModal(book, bookTransactions);
          cameraController.start();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showBookDetailsModal(
    BookModel book,
    List<TransactionModel> transactions,
  ) async {
    final currentlyHeld =
        transactions.where((t) => t.status == 'ISSUED').toList();
    final overdue = transactions.where((t) => t.status == 'OVERDUE').toList();
    final returned = transactions.where((t) => t.status == 'RETURNED').toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Book Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book.coverUrl!,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 60,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF9B5DE5)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_stories_rounded,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF9B5DE5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 32),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(book.author,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            )),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: book.isAvailable
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.isAvailable
                                ? '${book.availableCopies}/${book.totalCopies} avail.'
                                : 'Not available',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF2A3550)),
              const SizedBox(height: 16),

              // Stats
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9,
                children: [
                  _buildStatBox('Held Now', currentlyHeld.length.toString(),
                      AppColors.accent, Icons.person_rounded),
                  _buildStatBox('Overdue', overdue.length.toString(),
                      AppColors.error, Icons.warning_amber_rounded),
                  _buildStatBox('Returned', returned.length.toString(),
                      AppColors.success, Icons.check_circle_rounded),
                ],
              ),
              const SizedBox(height: 20),

              // Currently Held By
              if (currentlyHeld.isNotEmpty) ...[
                Text('Currently Held By',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 12),
                ...currentlyHeld.map((t) => _buildStudentRow(t)),
                const SizedBox(height: 16),
              ],

              // Overdue
              if (overdue.isNotEmpty) ...[
                Text('Overdue Copies',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    )),
                const SizedBox(height: 12),
                ...overdue.map((t) => _buildOverdueRow(t)),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibrarianBookDetailScreen(
                              book: book,
                              token: context.read<AuthProvider>().user!.token,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Full Details',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bgPrimary,
                        side: const BorderSide(color: Color(0xFF2A3550)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(TransactionModel t) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (t.studentRegistration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Reg: ${t.studentRegistration}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(t.dueDate)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (t.isOverdue)
                Text(
                  'Overdue by ${t.daysOverdue} day${t.daysOverdue != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueRow(TransactionModel t) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (t.studentRegistration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Reg: ${t.studentRegistration}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Overdue',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Overdue by ${t.daysOverdue} day${t.daysOverdue != 1 ? 's' : ''} • Due: ${DateFormat('MMM d, yyyy').format(t.dueDate)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 30.0;
    const cornerWidth = 4.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerWidth;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength),
        paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height),
        Offset(cornerLength, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(CornersPainter oldDelegate) => false;
}
